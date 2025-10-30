package moe.sekiu.minilpa.web.controller

import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/api/test")
class TestController {
    
    @GetMapping("/ws-config")
    fun testWebSocketConfig(): ResponseEntity<Map<String, Any>> {
        return ResponseEntity.ok(mapOf(
            "message" to "WebSocket配置测试",
            "endpoint" to "/ws/agent",
            "status" to "配置类已加载"
        ))
    }
}

