package moe.sekiu.minilpa.web.service

import moe.sekiu.minilpa.web.model.WebSocketMessage
import moe.sekiu.minilpa.web.config.BackendProperties
import org.springframework.stereotype.Service
import java.util.concurrent.ConcurrentHashMap
import java.util.UUID
import io.micrometer.core.instrument.MeterRegistry
import io.micrometer.core.instrument.Timer

@Service
class AgentConnectionService(
    private val backendProperties: BackendProperties,
    private val meterRegistry: MeterRegistry
) {
    private val connectedAgents = ConcurrentHashMap<String, AgentSession>()

    data class AgentSession(
        val id: String,
        val connectedAt: Long = System.currentTimeMillis()
    )

    fun registerAgent(sessionId: String): String {
        val agentId = UUID.randomUUID().toString()
        connectedAgents[agentId] = AgentSession(id = sessionId) // 使用 sessionId 而不是 agentId
        notifyAgentConnected(agentId)
        return agentId
    }

    fun unregisterAgent(sessionId: String) {
        val agentId = connectedAgents.values.find { it.id == sessionId }?.id
        agentId?.let {
            connectedAgents.remove(it)
            notifyAgentDisconnected(it)
        }
    }

    private val webSocketSessions = ConcurrentHashMap<String, Any>() // WebSocketSession
    private val clientWebSocketSessions = ConcurrentHashMap<String, org.springframework.web.socket.WebSocketSession>()
    private val log = org.slf4j.LoggerFactory.getLogger(javaClass)
    private val agentLocks = java.util.concurrent.ConcurrentHashMap<String, java.util.concurrent.Semaphore>()
    
    fun registerWebSocketSession(sessionId: String, session: Any) {
        webSocketSessions[sessionId] = session
    }

    fun registerClientSession(sessionId: String, session: org.springframework.web.socket.WebSocketSession) {
        clientWebSocketSessions[sessionId] = session
    }

    fun unregisterClientSession(sessionId: String) {
        clientWebSocketSessions.remove(sessionId)
    }
    
    fun sendCommand(agentId: String, command: WebSocketMessage.Command): Boolean {
        val session = connectedAgents[agentId] ?: return false
        // 使用直接 WebSocket 发送命令
        return sendCommandToWebSocket(session.id, command)
    }
    
    fun sendCommandToWebSocket(sessionId: String, command: Any): Boolean {
        val session = webSocketSessions[sessionId] as? org.springframework.web.socket.WebSocketSession ?: return false
        return try {
            val objectMapper = com.fasterxml.jackson.databind.ObjectMapper()
            val message = objectMapper.writeValueAsString(command)
            session.sendMessage(org.springframework.web.socket.TextMessage(message))
            true
        } catch (e: Exception) {
            log.error("发送命令失败", e)
            false
        }
    }
    
    // 用于存储等待响应的请求
    private val pendingRequests = java.util.concurrent.ConcurrentHashMap<String, java.util.concurrent.CompletableFuture<Map<String, Any>>>()
    
    fun sendCommandAndWait(sessionId: String, command: Map<String, Any>, timeoutMillis: Long = 30000): Map<String, Any>? {
        val requestId = java.util.UUID.randomUUID().toString()
        val future = java.util.concurrent.CompletableFuture<Map<String, Any>>()
        pendingRequests[requestId] = future
        
        try {
            val commandWithId = command.toMutableMap()
            commandWithId["requestId"] = requestId
            
            if (sendCommandToWebSocket(sessionId, commandWithId)) {
                return try {
                    future.get(timeoutMillis, java.util.concurrent.TimeUnit.MILLISECONDS)
                } catch (e: java.util.concurrent.TimeoutException) {
                    log.error("等待响应超时: requestId=$requestId")
                    null
                } catch (e: Exception) {
                    log.error("等待响应失败", e)
                    null
                }
            } else {
                return null
            }
        } finally {
            pendingRequests.remove(requestId)
        }
    }

    fun sendCommandAndWaitWithRetry(
        sessionId: String,
        command: Map<String, Any>,
        timeoutMillis: Long = backendProperties.command.timeoutMs,
        retries: Int = backendProperties.command.retries
    ): Map<String, Any>? {
        val type = command["type"]?.toString() ?: "unknown"
        val timer = Timer.builder("minilpa.command.duration")
            .tag("type", type)
            .register(meterRegistry)
        return moe.sekiu.minilpa.web.util.RetryUtils.retry(times = retries + 1) {
            val success = BooleanArray(1)
            val result = timer.recordCallable {
                val res = sendCommandAndWait(sessionId, command, timeoutMillis)
                success[0] = (res?.get("success") == true)
                res
            }
            log.info("command_executed type={} success={}", type, success[0])
            if (result == null) throw RuntimeException("command timeout or failed")
            result
        }
    }

    fun <T> withAgentExclusive(agentSessionId: String, block: () -> T): T {
        val sem = agentLocks.computeIfAbsent(agentSessionId) { java.util.concurrent.Semaphore(1) }
        sem.acquire()
        return try {
            block()
        } finally {
            sem.release()
        }
    }
    
    fun handleAgentResponse(sessionId: String, response: Map<String, Any>) {
        val requestId = response["requestId"] as? String
        if (requestId != null) {
            val future = pendingRequests.remove(requestId)
            if (future != null) {
                future.complete(response)
            } else {
                log.warn("收到未知requestId的响应: $requestId")
            }
        } else {
            log.debug("收到无requestId的响应，可能是主动推送消息")
        }
    }

    fun broadcastToClients(topic: String, message: Any) {
        try {
            val objectMapper = com.fasterxml.jackson.databind.ObjectMapper()
            val text = objectMapper.writeValueAsString(mapOf("topic" to topic, "data" to message))
            clientWebSocketSessions.values.forEach { session ->
                if (session.isOpen) session.sendMessage(org.springframework.web.socket.TextMessage(text))
            }
        } catch (e: Exception) {
            log.error("广播消息失败", e)
        }
    }

    fun getConnectedAgents(): Map<String, AgentSession> {
        return connectedAgents.toMap()
    }

    fun hasConnectedAgents(): Boolean {
        return connectedAgents.isNotEmpty()
    }

    private fun notifyAgentConnected(agentId: String) {
        broadcastToClients("agent-status", mapOf(
            "type" to "connected",
            "agentId" to agentId
        ))
    }

    private fun notifyAgentDisconnected(agentId: String) {
        broadcastToClients("agent-status", mapOf(
            "type" to "disconnected",
            "agentId" to agentId
        ))
    }

    fun resolveSessionIdByAgentIdOrFirst(agentId: String?): String? {
        if (connectedAgents.isEmpty()) return null
        if (agentId.isNullOrBlank()) return connectedAgents.values.firstOrNull()?.id
        val session = connectedAgents[agentId]
        return session?.id ?: connectedAgents.values.firstOrNull()?.id
    }
}

