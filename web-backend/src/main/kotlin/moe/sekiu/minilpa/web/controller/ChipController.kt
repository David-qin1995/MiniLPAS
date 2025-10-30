package moe.sekiu.minilpa.web.controller

import moe.sekiu.minilpa.web.model.ApiResponse
import moe.sekiu.minilpa.web.model.ChipInfo
import moe.sekiu.minilpa.web.service.AgentConnectionService
import moe.sekiu.minilpa.web.service.CacheService
import org.springframework.http.ResponseEntity
import org.springframework.validation.annotation.Validated
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/chip")
@Validated
class ChipController(
    private val agentConnectionService: AgentConnectionService,
    private val cacheService: CacheService
) {

    @GetMapping("/info")
    fun getChipInfo(@RequestParam(required = false) agentId: String?): ResponseEntity<ApiResponse<ChipInfo>> {
        val sessionId = agentConnectionService.resolveSessionIdByAgentIdOrFirst(agentId)
        if (sessionId == null) {
            return ResponseEntity.ok(ApiResponse(
                success = false,
                error = "没有已连接的代理"
            ))
        }
        
        
        val cacheKey = "chipinfo:$sessionId"
        cacheService.get<ChipInfo>(cacheKey)?.let {
            return ResponseEntity.ok(ApiResponse(success = true, data = it))
        }

        val command = mapOf(
            "type" to "get-chip-info"
        )
        
        val response = agentConnectionService.sendCommandAndWaitWithRetry(sessionId, command, 30_000, 2)
        
        return if (response != null && response["success"] == true) {
            try {
                val dataStr = response["data"] as? String
                if (dataStr != null) {
                    val objectMapper = com.fasterxml.jackson.databind.ObjectMapper()
                    val chipData = objectMapper.readValue(dataStr, Map::class.java) as Map<*, *>
                    
                    // 从chipData中提取信息（适配LPAC返回的格式）
                    val eidValue = chipData["eidValue"] as? String
                    val euiccAddresses = chipData["EuiccConfiguredAddresses"] as? Map<*, *>
                    val defaultDpAddress = euiccAddresses?.get("defaultDpAddress") as? String
                    
                    val chipInfo = ChipInfo(
                        eid = eidValue,
                        iccid = null, // LPAC可能返回在不同字段
                        defaultSmdp = defaultDpAddress
                    )
                    cacheService.put(cacheKey, chipInfo, 5_000)
                    ResponseEntity.ok(ApiResponse(success = true, data = chipInfo))
                } else {
                    ResponseEntity.ok(ApiResponse(success = false, error = "响应数据为空"))
                }
            } catch (e: Exception) {
                ResponseEntity.ok(ApiResponse(success = false, error = "解析响应失败: ${e.message}"))
            }
        } else {
            val errorMsg = response?.get("error") as? String ?: "获取芯片信息失败"
            ResponseEntity.ok(ApiResponse(success = false, error = errorMsg))
        }
    }
}

