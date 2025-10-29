package moe.sekiu.minilpa.web.controller

import moe.sekiu.minilpa.web.model.*
import moe.sekiu.minilpa.web.service.AgentConnectionService
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/notifications")
class NotificationController(
    private val agentConnectionService: AgentConnectionService
) {
    
    @GetMapping
    fun getNotifications(@RequestParam(required = false) agentId: String?): ResponseEntity<ApiResponse<List<Notification>>> {
        val agents = agentConnectionService.getConnectedAgents()
        if (agents.isEmpty()) {
            return ResponseEntity.ok(ApiResponse(
                success = false,
                error = "没有已连接的代理"
            ))
        }
        
        val firstAgent = agents.values.first()
        val sessionId = firstAgent.id
        
        val command = mapOf("type" to "get-notifications")
        val response = agentConnectionService.sendCommandAndWait(sessionId, command)
        
        return if (response != null && response["success"] == true) {
            try {
                val dataStr = response["data"] as? String
                if (dataStr != null) {
                    val objectMapper = com.fasterxml.jackson.databind.ObjectMapper()
                    val notificationsData = objectMapper.readValue(dataStr, List::class.java) as List<Map<*, *>>
                    
                    val notifications = notificationsData.map { notifData ->
                        Notification(
                            seq = (notifData["seqNumber"] as? Number)?.toInt() ?: 0,
                            profileManagementOperation = (notifData["profileManagementOperation"] as? String) ?: "",
                            iccid = notifData["iccid"] as? String,
                            notificationAddress = notifData["notificationAddress"] as? String
                        )
                    }
                    
                    ResponseEntity.ok(ApiResponse(success = true, data = notifications))
                } else {
                    ResponseEntity.ok(ApiResponse(success = true, data = emptyList()))
                }
            } catch (e: Exception) {
                ResponseEntity.ok(ApiResponse(success = false, error = "解析响应失败: ${e.message}"))
            }
        } else {
            val errorMsg = response?.get("error") as? String ?: "获取通知列表失败"
            ResponseEntity.ok(ApiResponse(success = false, error = errorMsg))
        }
    }
    
    @PostMapping("/process")
    fun processNotification(
        @RequestBody request: Map<String, Any>
    ): ResponseEntity<ApiResponse<Unit>> {
        val agents = agentConnectionService.getConnectedAgents()
        if (agents.isEmpty()) {
            return ResponseEntity.ok(ApiResponse(success = false, error = "没有已连接的代理"))
        }
        
        val firstAgent = agents.values.first()
        val sessionId = firstAgent.id
        
        val seq = request["seq"] as? List<Int> ?: emptyList()
        val remove = request["remove"] as? Boolean ?: false
        
        val command = mapOf(
            "type" to "process-notification",
            "payload" to mapOf(
                "seq" to seq,
                "remove" to remove
            )
        )
        
        val response = agentConnectionService.sendCommandAndWait(sessionId, command)
        
        return if (response != null && response["success"] == true) {
            ResponseEntity.ok(ApiResponse(success = true, message = response["data"] as? String))
        } else {
            val errorMsg = response?.get("error") as? String ?: "处理通知失败"
            ResponseEntity.ok(ApiResponse(success = false, error = errorMsg))
        }
    }
    
    @DeleteMapping
    fun removeNotification(@RequestBody request: Map<String, List<Int>>): ResponseEntity<ApiResponse<Unit>> {
        val agents = agentConnectionService.getConnectedAgents()
        if (agents.isEmpty()) {
            return ResponseEntity.ok(ApiResponse(success = false, error = "没有已连接的代理"))
        }
        
        val firstAgent = agents.values.first()
        val sessionId = firstAgent.id
        
        val seq = request["seq"] ?: emptyList()
        
        val command = mapOf(
            "type" to "remove-notification",
            "payload" to mapOf(
                "seq" to seq
            )
        )
        
        val response = agentConnectionService.sendCommandAndWait(sessionId, command)
        
        return if (response != null && response["success"] == true) {
            ResponseEntity.ok(ApiResponse(success = true, message = response["data"] as? String))
        } else {
            val errorMsg = response?.get("error") as? String ?: "删除通知失败"
            ResponseEntity.ok(ApiResponse(success = false, error = errorMsg))
        }
    }
}

