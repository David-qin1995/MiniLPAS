package moe.sekiu.minilpa.web.controller

import moe.sekiu.minilpa.web.service.AgentConnectionService
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Component
import org.springframework.web.socket.CloseStatus
import org.springframework.web.socket.TextMessage
import org.springframework.web.socket.WebSocketSession
import org.springframework.web.socket.handler.TextWebSocketHandler

@Component
class ClientWebSocketHandler(
    private val agentConnectionService: AgentConnectionService
) : TextWebSocketHandler() {

    private val log = LoggerFactory.getLogger(javaClass)

    override fun afterConnectionEstablished(session: WebSocketSession) {
        log.info("客户端订阅连接已建立: ${session.id}")
        agentConnectionService.registerClientSession(session.id, session)
    }

    override fun handleTextMessage(session: WebSocketSession, message: TextMessage) {
        // 前端无需发送消息，忽略
        log.debug("客户端消息: ${message.payload}")
    }

    override fun afterConnectionClosed(session: WebSocketSession, status: CloseStatus) {
        log.info("客户端订阅连接已关闭: ${session.id}")
        agentConnectionService.unregisterClientSession(session.id)
    }
}


