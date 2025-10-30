package moe.sekiu.minilpa.web.service

import moe.sekiu.minilpa.web.model.WebSocketMessage
import org.springframework.stereotype.Service
import java.util.concurrent.ConcurrentHashMap
import java.util.UUID

@Service
class AgentConnectionService {
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
    private val log = org.slf4j.LoggerFactory.getLogger(javaClass)
    
    fun registerWebSocketSession(sessionId: String, session: Any) {
        webSocketSessions[sessionId] = session
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
        // 暂时不使用STOMP，直接通过WebSocket发送
        // messagingTemplate.convertAndSend("/topic/$topic", message)
        // TODO: 实现前端WebSocket广播（当需要时）
        log.info("广播消息到主题: $topic")
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
}

