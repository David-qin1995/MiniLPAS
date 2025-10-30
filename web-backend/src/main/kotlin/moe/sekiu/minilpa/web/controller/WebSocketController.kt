package moe.sekiu.minilpa.web.controller

import moe.sekiu.minilpa.web.model.WebSocketMessage
import moe.sekiu.minilpa.web.service.AgentConnectionService
import org.springframework.messaging.handler.annotation.MessageMapping
import org.springframework.messaging.handler.annotation.Payload
import org.springframework.messaging.simp.SimpMessageHeaderAccessor
import org.springframework.stereotype.Controller

@Controller
class WebSocketController(
    private val agentConnectionService: AgentConnectionService
) {

    @MessageMapping("/agent/connect")
    fun handleAgentConnect(
        headerAccessor: SimpMessageHeaderAccessor,
        @Payload message: Map<String, Any>
    ): WebSocketMessage.Response {
        val sessionId = headerAccessor.sessionId ?: return WebSocketMessage.Response(
            success = false,
            error = "No session ID"
        )
        
        val agentId = agentConnectionService.registerAgent(sessionId)
        return WebSocketMessage.Response(
            success = true,
            data = agentId
        )
    }

    @MessageMapping("/agent/disconnect")
    fun handleAgentDisconnect(headerAccessor: SimpMessageHeaderAccessor) {
        val sessionId = headerAccessor.sessionId
        sessionId?.let { agentConnectionService.unregisterAgent(it) }
    }

    @MessageMapping("/agent/response")
    fun handleAgentResponse(
        @Payload response: WebSocketMessage.Response
    ) {
        // 将代理的响应广播给所有客户端
        agentConnectionService.broadcastToClients("agent-response", response)
    }

    @MessageMapping("/agent/progress")
    fun handleAgentProgress(
        @Payload progress: WebSocketMessage.Progress
    ) {
        // 广播进度更新
        agentConnectionService.broadcastToClients("progress", progress)
    }

    @MessageMapping("/client/command")
    fun handleClientCommand(
        @Payload command: WebSocketMessage.Command
    ): WebSocketMessage.Response {
        // 将客户端命令转发到第一个连接的代理
        val agents = agentConnectionService.getConnectedAgents()
        if (agents.isEmpty()) {
            return WebSocketMessage.Response(
                success = false,
                error = "No agent connected"
            )
        }
        
        val agentId = agents.keys.first()
        val sent = agentConnectionService.sendCommand(agentId, command)
        
        return WebSocketMessage.Response(
            success = sent,
            error = if (!sent) "Failed to send command" else null
        )
    }
}

