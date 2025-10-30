package moe.sekiu.minilpa.web.controller

import com.fasterxml.jackson.databind.ObjectMapper
import moe.sekiu.minilpa.web.service.AgentConnectionService
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Component
import org.springframework.web.socket.CloseStatus
import org.springframework.web.socket.TextMessage
import org.springframework.web.socket.WebSocketSession
import org.springframework.web.socket.handler.TextWebSocketHandler

@Component
class AgentWebSocketHandler(
    private val agentConnectionService: AgentConnectionService,
    private val objectMapper: ObjectMapper
) : TextWebSocketHandler() {
    
    private val log = LoggerFactory.getLogger(javaClass)
    
    override fun afterConnectionEstablished(session: WebSocketSession) {
        log.info("代理连接已建立: ${session.id}")
        val agentId = agentConnectionService.registerAgent(session.id)
        agentConnectionService.registerWebSocketSession(session.id, session)
        log.info("已注册代理: $agentId")
    }
    
    override fun afterConnectionClosed(session: WebSocketSession, status: CloseStatus) {
        log.info("代理连接已关闭: ${session.id}, 状态: $status")
        agentConnectionService.unregisterAgent(session.id)
    }
    
    override fun handleTextMessage(session: WebSocketSession, message: TextMessage) {
        log.debug("收到代理消息: ${message.payload}")
        try {
            val data = objectMapper.readValue(message.payload, Map::class.java) as Map<String, Any>
            val type = data["type"] as? String
            
            when (type) {
                "response" -> {
                    // 处理代理响应，如果有requestId则完成对应的CompletableFuture
                    agentConnectionService.handleAgentResponse(session.id, data)
                    // 同时广播给客户端
                    agentConnectionService.broadcastToClients("agent-response", data)
                }
                "progress" -> {
                    agentConnectionService.broadcastToClients("progress", data)
                }
                else -> {
                    log.warn("未知消息类型: $type")
                }
            }
        } catch (e: Exception) {
            log.error("处理消息失败", e)
        }
    }
    
    override fun handleTransportError(session: WebSocketSession, exception: Throwable) {
        log.error("传输错误: ${session.id}", exception)
    }
}

