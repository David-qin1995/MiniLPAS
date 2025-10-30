package moe.sekiu.minilpa.web.config

import moe.sekiu.minilpa.web.controller.AgentWebSocketHandler
import org.springframework.context.annotation.Configuration
import org.springframework.web.socket.config.annotation.EnableWebSocket
import org.springframework.web.socket.config.annotation.WebSocketConfigurer
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry

@Configuration
@EnableWebSocket
class PlainWebSocketConfig(
    private val agentWebSocketHandler: AgentWebSocketHandler
) : WebSocketConfigurer {
    
    override fun registerWebSocketHandlers(registry: WebSocketHandlerRegistry) {
        // 代理连接路径
        registry.addHandler(agentWebSocketHandler, "/ws/agent")
            .setAllowedOriginPatterns("*")
    }
}

