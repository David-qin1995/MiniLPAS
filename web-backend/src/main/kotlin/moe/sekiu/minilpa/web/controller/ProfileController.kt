package moe.sekiu.minilpa.web.controller

import moe.sekiu.minilpa.web.model.*
import moe.sekiu.minilpa.web.service.AgentConnectionService
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/profiles")
class ProfileController(
    private val agentConnectionService: AgentConnectionService
) {

    @GetMapping
    fun getProfiles(@RequestParam(required = false) agentId: String?): ResponseEntity<ApiResponse<List<Profile>>> {
        val agents = agentConnectionService.getConnectedAgents()
        if (agents.isEmpty()) {
            return ResponseEntity.ok(ApiResponse(
                success = false,
                error = "没有已连接的代理"
            ))
        }
        
        val firstAgent = agents.values.first()
        val sessionId = firstAgent.id
        
        val command = mapOf("type" to "get-profiles")
        val response = agentConnectionService.sendCommandAndWait(sessionId, command)
        
        return if (response != null && response["success"] == true) {
            try {
                val dataStr = response["data"] as? String
                if (dataStr != null) {
                    val objectMapper = com.fasterxml.jackson.databind.ObjectMapper()
                    val profilesData = objectMapper.readValue(dataStr, List::class.java) as List<Map<*, *>>
                    
                    val profiles = profilesData.map { profileData ->
                        Profile(
                            iccid = profileData["iccid"] as? String ?: "",
                            state = (profileData["profileState"] as? String)?.lowercase() ?: "disabled",
                            serviceProviderName = profileData["serviceProviderName"] as? String,
                            profileName = profileData["profileName"] as? String,
                            nickname = profileData["profileNickname"] as? String
                        )
                    }
                    
                    ResponseEntity.ok(ApiResponse(success = true, data = profiles))
                } else {
                    ResponseEntity.ok(ApiResponse(success = true, data = emptyList()))
                }
            } catch (e: Exception) {
                ResponseEntity.ok(ApiResponse(success = false, error = "解析响应失败: ${e.message}"))
            }
        } else {
            val errorMsg = response?.get("error") as? String ?: "获取配置文件列表失败"
            ResponseEntity.ok(ApiResponse(success = false, error = errorMsg))
        }
    }

    @PostMapping("/download")
    fun downloadProfile(@RequestBody request: DownloadProfileRequest): ResponseEntity<ApiResponse<Unit>> {
        val agents = agentConnectionService.getConnectedAgents()
        if (agents.isEmpty()) {
            return ResponseEntity.ok(ApiResponse(success = false, error = "没有已连接的代理"))
        }
        
        val firstAgent = agents.values.first()
        val sessionId = firstAgent.id
        
        val command = mapOf(
            "type" to "download-profile",
            "payload" to mapOf(
                "smdp" to request.smdp,
                "matchingId" to request.matchingId,
                "confirmCode" to request.confirmCodeOrNull,
                "imei" to request.imei
            )
        )
        
        val response = agentConnectionService.sendCommandAndWait(sessionId, command, 60000) // 下载可能需要更长时间
        
        return if (response != null && response["success"] == true) {
            ResponseEntity.ok(ApiResponse(success = true, message = response["data"] as? String))
        } else {
            val errorMsg = response?.get("error") as? String ?: "下载失败"
            ResponseEntity.ok(ApiResponse(success = false, error = errorMsg))
        }
    }

    @PostMapping("/{iccid}/enable")
    fun enableProfile(@PathVariable iccid: String): ResponseEntity<ApiResponse<Unit>> {
        val agents = agentConnectionService.getConnectedAgents()
        if (agents.isEmpty()) {
            return ResponseEntity.ok(ApiResponse(success = false, error = "没有已连接的代理"))
        }
        
        val firstAgent = agents.values.first()
        val sessionId = firstAgent.id
        
        val command = mapOf(
            "type" to "enable-profile",
            "iccid" to iccid
        )
        
        val response = agentConnectionService.sendCommandAndWait(sessionId, command)
        
        return if (response != null && response["success"] == true) {
            ResponseEntity.ok(ApiResponse(success = true, message = response["data"] as? String))
        } else {
            val errorMsg = response?.get("error") as? String ?: "启用失败"
            ResponseEntity.ok(ApiResponse(success = false, error = errorMsg))
        }
    }

    @PostMapping("/{iccid}/disable")
    fun disableProfile(@PathVariable iccid: String): ResponseEntity<ApiResponse<Unit>> {
        val agents = agentConnectionService.getConnectedAgents()
        if (agents.isEmpty()) {
            return ResponseEntity.ok(ApiResponse(success = false, error = "没有已连接的代理"))
        }
        
        val firstAgent = agents.values.first()
        val sessionId = firstAgent.id
        
        val command = mapOf(
            "type" to "disable-profile",
            "iccid" to iccid
        )
        
        val response = agentConnectionService.sendCommandAndWait(sessionId, command)
        
        return if (response != null && response["success"] == true) {
            ResponseEntity.ok(ApiResponse(success = true, message = response["data"] as? String))
        } else {
            val errorMsg = response?.get("error") as? String ?: "禁用失败"
            ResponseEntity.ok(ApiResponse(success = false, error = errorMsg))
        }
    }

    @DeleteMapping("/{iccid}")
    fun deleteProfile(@PathVariable iccid: String): ResponseEntity<ApiResponse<Unit>> {
        val agents = agentConnectionService.getConnectedAgents()
        if (agents.isEmpty()) {
            return ResponseEntity.ok(ApiResponse(success = false, error = "没有已连接的代理"))
        }
        
        val firstAgent = agents.values.first()
        val sessionId = firstAgent.id
        
        val command = mapOf(
            "type" to "delete-profile",
            "iccid" to iccid
        )
        
        val response = agentConnectionService.sendCommandAndWait(sessionId, command)
        
        return if (response != null && response["success"] == true) {
            ResponseEntity.ok(ApiResponse(success = true, message = response["data"] as? String))
        } else {
            val errorMsg = response?.get("error") as? String ?: "删除失败"
            ResponseEntity.ok(ApiResponse(success = false, error = errorMsg))
        }
    }

    @PutMapping("/{iccid}/nickname")
    fun setNickname(
        @PathVariable iccid: String,
        @RequestBody nickname: Map<String, String>
    ): ResponseEntity<ApiResponse<Unit>> {
        val agents = agentConnectionService.getConnectedAgents()
        if (agents.isEmpty()) {
            return ResponseEntity.ok(ApiResponse(success = false, error = "没有已连接的代理"))
        }
        
        val firstAgent = agents.values.first()
        val sessionId = firstAgent.id
        
        val command = mapOf(
            "type" to "set-profile-nickname",
            "iccid" to iccid,
            "nickname" to (nickname["nickname"] ?: "")
        )
        
        val response = agentConnectionService.sendCommandAndWait(sessionId, command)
        
        return if (response != null && response["success"] == true) {
            ResponseEntity.ok(ApiResponse(success = true, message = response["data"] as? String))
        } else {
            val errorMsg = response?.get("error") as? String ?: "更新昵称失败"
            ResponseEntity.ok(ApiResponse(success = false, error = errorMsg))
        }
    }
}

