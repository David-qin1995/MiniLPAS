package moe.sekiu.minilpa.web.config

import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.web.socket.server.standard.ServletServerContainerFactoryBean

@Configuration
class WebSocketIdleConfig {

    @Bean
    fun createWebSocketContainer(): ServletServerContainerFactoryBean {
        val container = ServletServerContainerFactoryBean()
        // 放宽 WS 空闲超时（30 分钟）
        container.maxSessionIdleTimeout = java.time.Duration.ofMinutes(30).toMillis()
        // 建议的缓冲区（可按需调整）
        container.setMaxTextMessageBufferSize(256 * 1024)
        container.setMaxBinaryMessageBufferSize(256 * 1024)
        return container
    }
}


