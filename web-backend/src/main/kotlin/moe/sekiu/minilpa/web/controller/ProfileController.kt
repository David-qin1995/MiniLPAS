package moe.sekiu.minilpa.web.controller

import moe.sekiu.minilpa.web.model.*
import moe.sekiu.minilpa.web.service.AgentConnectionService
import moe.sekiu.minilpa.web.service.CacheService
import org.slf4j.LoggerFactory
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*
import org.springframework.validation.annotation.Validated
import jakarta.validation.Valid
import moe.sekiu.minilpa.web.util.Validators

@RestController
@RequestMapping("/api/profiles")
@Validated
class ProfileController(
    private val agentConnectionService: AgentConnectionService,
    private val cacheService: CacheService
) {

    private val log = LoggerFactory.getLogger(javaClass)

    @GetMapping
    fun getProfiles(@RequestParam(required = false) agentId: String?): ResponseEntity<ApiResponse<List<Profile>>> {
        val sessionId = agentConnectionService.resolveSessionIdByAgentIdOrFirst(agentId)
        if (sessionId == null) {
            return ResponseEntity.ok(ApiResponse(
                success = false,
                error = "没有已连接的代理"
            ))
        }

        val cacheKey = "profiles:$sessionId"
        cacheService.get<List<Profile>>(cacheKey)?.let {
            return ResponseEntity.ok(ApiResponse(success = true, data = it))
        }

        val command = mapOf("type" to "get-profiles")
        val response = agentConnectionService.sendCommandAndWaitWithRetry(sessionId, command, 30000, 2)

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
                    cacheService.put(cacheKey, profiles, 2_000)
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
    fun downloadProfile(@RequestBody @Valid request: DownloadProfileRequest, @RequestParam(required = false) agentId: String?): ResponseEntity<ApiResponse<Unit>> {
        val sessionId = agentConnectionService.resolveSessionIdByAgentIdOrFirst(agentId)
        if (sessionId == null) {
            return ResponseEntity.ok(ApiResponse(success = false, error = "没有已连接的代理"))
        }

        if (request.smdp.isBlank() || request.matchingId.isBlank()) {
            throw IllegalArgumentException("smdp 与 matchingId 不能为空")
        }
        Validators.requireValidSmdp(request.smdp)

        val command = mapOf(
            "type" to "download-profile",
            "payload" to mapOf(
                "smdp" to request.smdp,
                "matchingId" to request.matchingId,
                "confirmCode" to request.confirmCodeOrNull,
                "imei" to request.imei
            )
        )

        val response = agentConnectionService.withAgentExclusive(sessionId) {
            cacheService.invalidate("profiles:$sessionId")
            agentConnectionService.sendCommandAndWaitWithRetry(sessionId, command, 120_000, 1)
        }

        return if (response != null && response["success"] == true) {
            ResponseEntity.ok(ApiResponse(success = true, message = response["data"] as? String))
        } else {
            val errorMsg = response?.get("error") as? String ?: "下载失败"
            ResponseEntity.ok(ApiResponse(success = false, error = errorMsg))
        }
    }

    @PostMapping("/{iccid}/enable")
    fun enableProfile(@PathVariable iccid: String, @RequestParam(required = false) agentId: String?): ResponseEntity<ApiResponse<Unit>> {
        Validators.requireValidIccid(iccid)
        val sessionId = agentConnectionService.resolveSessionIdByAgentIdOrFirst(agentId)
        if (sessionId == null) {
            return ResponseEntity.ok(ApiResponse(success = false, error = "没有已连接的代理"))
        }

        val command = mapOf(
            "type" to "enable-profile",
            "iccid" to iccid
        )

        val response = agentConnectionService.withAgentExclusive(sessionId) {
            cacheService.invalidate("profiles:$sessionId")
            agentConnectionService.sendCommandAndWaitWithRetry(sessionId, command, 30_000, 2)
        }

        return if (response != null && response["success"] == true) {
            ResponseEntity.ok(ApiResponse(success = true, message = response["data"] as? String))
        } else {
            val errorMsg = response?.get("error") as? String ?: "启用失败"
            ResponseEntity.ok(ApiResponse(success = false, error = errorMsg))
        }
    }

    @PostMapping("/{iccid}/disable")
    fun disableProfile(@PathVariable iccid: String, @RequestParam(required = false) agentId: String?): ResponseEntity<ApiResponse<Unit>> {
        Validators.requireValidIccid(iccid)
        val sessionId = agentConnectionService.resolveSessionIdByAgentIdOrFirst(agentId)
        if (sessionId == null) {
            return ResponseEntity.ok(ApiResponse(success = false, error = "没有已连接的代理"))
        }

        val command = mapOf(
            "type" to "disable-profile",
            "iccid" to iccid
        )

        val response = agentConnectionService.withAgentExclusive(sessionId) {
            cacheService.invalidate("profiles:$sessionId")
            agentConnectionService.sendCommandAndWaitWithRetry(sessionId, command, 30_000, 2)
        }

        return if (response != null && response["success"] == true) {
            ResponseEntity.ok(ApiResponse(success = true, message = response["data"] as? String))
        } else {
            val errorMsg = response?.get("error") as? String ?: "禁用失败"
            ResponseEntity.ok(ApiResponse(success = false, error = errorMsg))
        }
    }

    @DeleteMapping("/{iccid}")
    fun deleteProfile(@PathVariable iccid: String, @RequestParam(required = false) agentId: String?): ResponseEntity<ApiResponse<Unit>> {
        Validators.requireValidIccid(iccid)
        val sessionId = agentConnectionService.resolveSessionIdByAgentIdOrFirst(agentId)
        if (sessionId == null) {
            return ResponseEntity.ok(ApiResponse(success = false, error = "没有已连接的代理"))
        }

        val command = mapOf(
            "type" to "delete-profile",
            "iccid" to iccid
        )

        val response = agentConnectionService.withAgentExclusive(sessionId) {
            cacheService.invalidate("profiles:$sessionId")
            agentConnectionService.sendCommandAndWaitWithRetry(sessionId, command, 30_000, 2)
        }

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
        @RequestBody nickname: Map<String, String>,
        @RequestParam(required = false) agentId: String?
    ): ResponseEntity<ApiResponse<Unit>> {
        val sessionId = agentConnectionService.resolveSessionIdByAgentIdOrFirst(agentId)
        if (sessionId == null) {
            return ResponseEntity.ok(ApiResponse(success = false, error = "没有已连接的代理"))
        }
        
        val value = nickname["nickname"]?.trim().orEmpty()
        if (value.isBlank()) throw IllegalArgumentException("nickname 不能为空")

        val command = mapOf(
            "type" to "set-profile-nickname",
            "iccid" to iccid,
            "nickname" to value
        )

        val response = agentConnectionService.withAgentExclusive(sessionId) {
            cacheService.invalidate("profiles:$sessionId")
            agentConnectionService.sendCommandAndWaitWithRetry(sessionId, command, 30_000, 1)
        }

        return if (response != null && response["success"] == true) {
            ResponseEntity.ok(ApiResponse(success = true, message = response["data"] as? String))
        } else {
            val errorMsg = response?.get("error") as? String ?: "更新昵称失败"
            ResponseEntity.ok(ApiResponse(success = false, error = errorMsg))
        }
    }
}

