package moe.sekiu.minilpa.web.model

import kotlinx.serialization.Serializable

// 通用响应
@Serializable
data class ApiResponse<T>(
    val success: Boolean,
    val data: T? = null,
    val message: String? = null,
    val error: String? = null
)

// 设备信息
@Serializable
data class DeviceInfo(
    val id: String,
    val name: String,
    val type: String,
    val connected: Boolean
)

// 芯片信息
@Serializable
data class ChipInfo(
    val eid: String? = null,
    val iccid: String? = null,
    val defaultSmdp: String? = null
)

// 配置文件
@Serializable
data class Profile(
    val iccid: String,
    val state: String,
    val serviceProviderName: String? = null,
    val profileName: String? = null,
    val nickname: String? = null
)

// 通知
@Serializable
data class Notification(
    val seq: Int,
    val profileManagementOperation: String,
    val iccid: String? = null,
    val notificationAddress: String? = null
)

// 下载配置请求
@Serializable
data class DownloadProfileRequest(
    val smdp: String,
    val matchingId: String,
    val confirmationCode: String? = null,
    val confirmCode: String? = null, // 兼容字段
    val imei: String? = null
) {
    val confirmCodeOrNull: String?
        get() = confirmationCode ?: confirmCode
}

// WebSocket 消息
@Serializable
sealed class WebSocketMessage {
    @Serializable
    data class Command(val type: String, val payload: Map<String, String> = emptyMap()) : WebSocketMessage()
    
    @Serializable
    data class Response(val success: Boolean, val data: String? = null, val error: String? = null) : WebSocketMessage()
    
    @Serializable
    data class Progress(val stage: String, val message: String) : WebSocketMessage()
    
    @Serializable
    data class Error(val message: String, val code: String? = null) : WebSocketMessage()
}

