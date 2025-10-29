package moe.sekiu.minilpa.web.controller

import moe.sekiu.minilpa.web.model.ApiResponse
import moe.sekiu.minilpa.web.model.DeviceInfo
import moe.sekiu.minilpa.web.service.AgentConnectionService
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/api/devices")
class DeviceController(
    private val agentConnectionService: AgentConnectionService
) {

    @GetMapping
    fun getDevices(): ResponseEntity<ApiResponse<List<DeviceInfo>>> {
        val devices = agentConnectionService.getConnectedAgents().map { (id, _) ->
            DeviceInfo(
                id = id,
                name = "Local Agent $id",
                type = "PCSC",
                connected = true
            )
        }
        
        return ResponseEntity.ok(ApiResponse(success = true, data = devices))
    }

    @GetMapping("/status")
    fun getConnectionStatus(): ResponseEntity<ApiResponse<Map<String, Any>>> {
        val status = mapOf<String, Any>(
            "connected" to agentConnectionService.hasConnectedAgents(),
            "agentCount" to agentConnectionService.getConnectedAgents().size
        )
        return ResponseEntity.ok(ApiResponse(success = true, data = status))
    }
}

