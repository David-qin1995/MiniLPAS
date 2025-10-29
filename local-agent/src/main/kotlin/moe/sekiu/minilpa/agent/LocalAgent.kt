package moe.sekiu.minilpa.agent

import kotlinx.coroutines.*
import kotlinx.serialization.json.*
import moe.sekiu.minilpa.agent.lpac.LPACExecutor
import moe.sekiu.minilpa.agent.model.*
import moe.sekiu.minilpa.agent.util.getAppDataFolder
import moe.sekiu.minilpa.agent.util.getPlatformInfo
import org.slf4j.LoggerFactory
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.WebSocket as OkWebSocket
import okhttp3.WebSocketListener
import java.io.File

class LocalAgent(
    private val serverUrl: String = "ws://localhost:8080/ws/agent"
) {
    private val log = LoggerFactory.getLogger(javaClass)
    private var webSocket: Any? = null  // 使用 OkHttp WebSocket
    private var lpacExecutor: LPACExecutor? = null
    private var selectedDriverEnv: String? = null
    
    init {
        // 初始化LPACExecutor
        try {
            val appDataFolder = getAppDataFolder(false)
            val platform = getPlatformInfo()
            val lpacFolder = File(appDataFolder, platform)
            lpacExecutor = LPACExecutor(lpacFolder, selectedDriverEnv)
            log.info("LPACExecutor初始化成功，路径: ${lpacFolder.absolutePath}")
        } catch (e: Exception) {
            log.warn("LPACExecutor初始化失败，将使用占位符功能: ${e.message}")
            lpacExecutor = null
        }
    }
    
    suspend fun start() = withContext(Dispatchers.Default) {
        var retryCount = 0
        val maxRetries = Int.MAX_VALUE // 无限重试
        
        while (retryCount < maxRetries && !Thread.currentThread().isInterrupted) {
            try {
                log.info("正在连接到服务器: $serverUrl (尝试 ${retryCount + 1})")
                
                // 使用 OkHttp WebSocket
                val client = OkHttpClient.Builder()
                    .readTimeout(30, java.util.concurrent.TimeUnit.SECONDS)
                    .writeTimeout(30, java.util.concurrent.TimeUnit.SECONDS)
                    .build()
                val request = Request.Builder().url(serverUrl).build()
                val listener = AgentWebSocketListener(this@LocalAgent)
                webSocket = client.newWebSocket(request, listener)
                
                log.info("WebSocket连接已建立")
                
                // 注册代理
                delay(500) // 等待连接稳定
                registerAgent()
                
                log.info("代理已注册，保持连接...")
                retryCount = 0 // 重置重试计数
                
                // 保持连接，直到断开
                while (webSocket != null && !Thread.currentThread().isInterrupted) {
                    delay(5000)
                    // 可以发送心跳包来检查连接状态
                }
            } catch (e: Exception) {
                log.error("连接失败: ${e.message}", e)
                retryCount++
                if (webSocket != null) {
                    try {
                        (webSocket as? OkWebSocket)?.close(1000, "Reconnecting")
                    } catch (ex: Exception) {
                        // 忽略关闭错误
                    }
                    webSocket = null
                }
                
                val waitTime = minOf(5000L * retryCount, 30000L) // 最多等待30秒
                log.info("等待 ${waitTime/1000} 秒后重试...")
                delay(waitTime)
            }
        }
    }
    
    private suspend fun registerAgent() {
        val message = JsonObject(mapOf(
            "type" to JsonPrimitive("agent-connect"),
            "agentId" to JsonPrimitive("local-agent-1")
        ))
        sendMessage(message)
    }
    
    private suspend fun sendMessage(message: JsonObject) {
        val json = Json.encodeToString(JsonObject.serializer(), message)
        (webSocket as? OkWebSocket)?.send(json)
    }
    
    private var currentRequestId: String? = null
    
    suspend fun handleCommand(command: JsonObject) {
        val type = command["type"]?.jsonPrimitive?.content ?: return
        currentRequestId = command["requestId"]?.jsonPrimitive?.content
        
        when (type) {
            "get-chip-info" -> handleGetChipInfo()
            "get-profiles" -> handleGetProfiles()
            "get-notifications" -> handleGetNotifications()
            "download-profile" -> handleDownloadProfile(command)
            "enable-profile" -> handleEnableProfile(command)
            "disable-profile" -> handleDisableProfile(command)
            "delete-profile" -> handleDeleteProfile(command)
            "set-profile-nickname" -> handleSetProfileNickname(command)
            "process-notification" -> handleProcessNotification(command)
            "remove-notification" -> handleRemoveNotification(command)
            "get-devices" -> handleGetDevices()
            "select-device" -> handleSelectDevice(command)
            else -> log.warn("未知命令类型: $type")
        }
    }
    
    private suspend fun handleGetChipInfo() {
        try {
            val executor = lpacExecutor ?: throw IllegalStateException("LPACExecutor未初始化")
            val chipInfo = executor.getChipInfo()
            val chipInfoJson = Json.encodeToString(moe.sekiu.minilpa.agent.model.ChipInfo.serializer(), chipInfo)
            sendResponse(true, chipInfoJson, null, currentRequestId)
        } catch (e: Exception) {
            log.error("获取芯片信息失败", e)
            sendResponse(false, null, e.message ?: "获取芯片信息失败", currentRequestId)
        }
    }
    
    private suspend fun handleGetProfiles() {
        try {
            val executor = lpacExecutor ?: throw IllegalStateException("LPACExecutor未初始化")
            val profiles = executor.getProfileList()
            val profilesJson = Json.encodeToString(kotlinx.serialization.builtins.ListSerializer(moe.sekiu.minilpa.agent.model.Profile.serializer()), profiles)
            sendResponse(true, profilesJson, null, currentRequestId)
        } catch (e: Exception) {
            log.error("获取配置文件列表失败", e)
            sendResponse(false, null, e.message ?: "获取配置文件列表失败", currentRequestId)
        }
    }
    
    private suspend fun handleGetNotifications() {
        try {
            val executor = lpacExecutor ?: throw IllegalStateException("LPACExecutor未初始化")
            val notifications = executor.getNotificationList()
            val notificationsJson = Json.encodeToString(kotlinx.serialization.builtins.ListSerializer(moe.sekiu.minilpa.agent.model.Notification.serializer()), notifications)
            sendResponse(true, notificationsJson, null, currentRequestId)
        } catch (e: Exception) {
            log.error("获取通知列表失败", e)
            sendResponse(false, null, e.message ?: "获取通知列表失败", currentRequestId)
        }
    }
    
    private suspend fun handleDownloadProfile(command: JsonObject) {
        try {
            val executor = lpacExecutor ?: throw IllegalStateException("LPACExecutor未初始化")
            val payload = command["payload"]?.jsonObject
            
            val smdp = payload?.get("smdp")?.jsonPrimitive?.content
            val matchingId = payload?.get("matchingId")?.jsonPrimitive?.content
            val confirmCode = payload?.get("confirmCode")?.jsonPrimitive?.content
            val imei = payload?.get("imei")?.jsonPrimitive?.content
            
            val downloadInfo = DownloadInfo(smdp, matchingId, confirmCode, imei)
            executor.downloadProfile(downloadInfo)
            sendResponse(true, "下载已启动", null, currentRequestId)
        } catch (e: Exception) {
            log.error("下载配置文件失败", e)
            sendResponse(false, null, e.message ?: "下载配置文件失败", currentRequestId)
        }
    }
    
    private suspend fun handleEnableProfile(command: JsonObject) {
        try {
            val executor = lpacExecutor ?: throw IllegalStateException("LPACExecutor未初始化")
            val iccid = command["iccid"]?.jsonPrimitive?.content 
                ?: throw IllegalArgumentException("缺少iccid参数")
            executor.enableProfile(iccid)
            sendResponse(true, "配置文件已启用", null, currentRequestId)
        } catch (e: Exception) {
            log.error("启用配置文件失败", e)
            sendResponse(false, null, e.message ?: "启用配置文件失败", currentRequestId)
        }
    }
    
    private suspend fun handleDisableProfile(command: JsonObject) {
        try {
            val executor = lpacExecutor ?: throw IllegalStateException("LPACExecutor未初始化")
            val iccid = command["iccid"]?.jsonPrimitive?.content 
                ?: throw IllegalArgumentException("缺少iccid参数")
            executor.disableProfile(iccid)
            sendResponse(true, "配置文件已禁用", null, currentRequestId)
        } catch (e: Exception) {
            log.error("禁用配置文件失败", e)
            sendResponse(false, null, e.message ?: "禁用配置文件失败", currentRequestId)
        }
    }
    
    private suspend fun handleDeleteProfile(command: JsonObject) {
        try {
            val executor = lpacExecutor ?: throw IllegalStateException("LPACExecutor未初始化")
            val iccid = command["iccid"]?.jsonPrimitive?.content 
                ?: throw IllegalArgumentException("缺少iccid参数")
            executor.deleteProfile(iccid)
            sendResponse(true, "配置文件已删除", null, currentRequestId)
        } catch (e: Exception) {
            log.error("删除配置文件失败", e)
            sendResponse(false, null, e.message ?: "删除配置文件失败", currentRequestId)
        }
    }
    
    private suspend fun handleSetProfileNickname(command: JsonObject) {
        try {
            val executor = lpacExecutor ?: throw IllegalStateException("LPACExecutor未初始化")
            val iccid = command["iccid"]?.jsonPrimitive?.content 
                ?: throw IllegalArgumentException("缺少iccid参数")
            val nickname = command["nickname"]?.jsonPrimitive?.content 
                ?: throw IllegalArgumentException("缺少nickname参数")
            executor.setProfileNickname(iccid, nickname)
            sendResponse(true, "昵称已更新", null, currentRequestId)
        } catch (e: Exception) {
            log.error("设置配置文件昵称失败", e)
            sendResponse(false, null, e.message ?: "设置配置文件昵称失败", currentRequestId)
        }
    }
    
    private suspend fun handleProcessNotification(command: JsonObject) {
        try {
            val executor = lpacExecutor ?: throw IllegalStateException("LPACExecutor未初始化")
            val payload = command["payload"]?.jsonObject
            val seqArray = payload?.get("seq")?.jsonArray 
                ?: throw IllegalArgumentException("缺少seq参数")
            val remove = payload?.get("remove")?.jsonPrimitive?.content?.toBoolean() ?: false
            val seq = seqArray.map { it.jsonPrimitive.content.toInt() }.toIntArray()
            executor.processNotification(*seq, remove = remove)
            sendResponse(true, "通知已处理", null, currentRequestId)
        } catch (e: Exception) {
            log.error("处理通知失败", e)
            sendResponse(false, null, e.message ?: "处理通知失败", currentRequestId)
        }
    }
    
    private suspend fun handleRemoveNotification(command: JsonObject) {
        try {
            val executor = lpacExecutor ?: throw IllegalStateException("LPACExecutor未初始化")
            val payload = command["payload"]?.jsonObject
            val seqArray = payload?.get("seq")?.jsonArray 
                ?: throw IllegalArgumentException("缺少seq参数")
            val seq = seqArray.map { it.jsonPrimitive.content.toInt() }.toIntArray()
            executor.removeNotification(*seq)
            sendResponse(true, "通知已删除", null, currentRequestId)
        } catch (e: Exception) {
            log.error("删除通知失败", e)
            sendResponse(false, null, e.message ?: "删除通知失败", currentRequestId)
        }
    }
    
    private suspend fun handleGetDevices() {
        try {
            val executor = lpacExecutor ?: throw IllegalStateException("LPACExecutor未初始化")
            val devices = executor.getDeviceList()
            val devicesJson = Json.encodeToString(kotlinx.serialization.builtins.ListSerializer(moe.sekiu.minilpa.agent.model.Driver.serializer()), devices)
            sendResponse(true, devicesJson, null, currentRequestId)
        } catch (e: Exception) {
            log.error("获取设备列表失败", e)
            sendResponse(false, null, e.message ?: "获取设备列表失败", currentRequestId)
        }
    }
    
    private suspend fun handleSelectDevice(command: JsonObject) {
        try {
            val driverEnv = command["driverEnv"]?.jsonPrimitive?.content
            selectedDriverEnv = driverEnv
            // 重新初始化LPACExecutor以使用新的驱动
            val appDataFolder = getAppDataFolder(false)
            val platform = getPlatformInfo()
            val lpacFolder = File(appDataFolder, platform)
            lpacExecutor = LPACExecutor(lpacFolder, selectedDriverEnv)
            sendResponse(true, "设备已选择", null, currentRequestId)
        } catch (e: Exception) {
            log.error("选择设备失败", e)
            sendResponse(false, null, e.message ?: "选择设备失败", currentRequestId)
        }
    }
    
    private suspend fun sendResponse(success: Boolean, data: String? = null, error: String? = null, requestId: String? = null) {
        val responseMap = mutableMapOf<String, JsonElement>()
        responseMap["type"] = JsonPrimitive("response")
        responseMap["success"] = JsonPrimitive(success)
        if (data != null) {
            responseMap["data"] = JsonPrimitive(data)
        } else {
            responseMap["data"] = JsonNull
        }
        if (error != null) {
            responseMap["error"] = JsonPrimitive(error)
        } else {
            responseMap["error"] = JsonNull
        }
        if (requestId != null) {
            responseMap["requestId"] = JsonPrimitive(requestId)
        }
        val response = JsonObject(responseMap)
        sendMessage(response)
    }
    
    fun stop() {
        (webSocket as? OkWebSocket)?.close(1000, "Agent stopping")
        webSocket = null
    }
}

// WebSocket 监听器 (使用 OkHttp)
class AgentWebSocketListener(private val agent: LocalAgent) : WebSocketListener() {
    private val log = LoggerFactory.getLogger(javaClass)
    
    override fun onOpen(webSocket: OkWebSocket, response: okhttp3.Response) {
        log.info("WebSocket 连接已打开")
    }
    
    override fun onMessage(webSocket: OkWebSocket, text: String) {
        log.debug("收到消息: $text")
        try {
            val jsonElement = Json.parseToJsonElement(text)
            if (jsonElement is JsonObject) {
                CoroutineScope(Dispatchers.Default).launch {
                    agent.handleCommand(jsonElement)
                }
            }
        } catch (e: Exception) {
            log.error("处理消息失败", e)
        }
    }
    
    override fun onFailure(webSocket: OkWebSocket, t: Throwable, response: okhttp3.Response?) {
        log.error("WebSocket 错误", t)
    }
    
    override fun onClosing(webSocket: OkWebSocket, code: Int, reason: String) {
        log.info("WebSocket 正在关闭: $code - $reason")
        webSocket.close(1000, null)
    }
    
    override fun onClosed(webSocket: OkWebSocket, code: Int, reason: String) {
        log.info("WebSocket 连接已关闭: $code - $reason")
    }
}

fun main() = runBlocking {
    val agent = LocalAgent()
    Runtime.getRuntime().addShutdownHook(Thread {
        agent.stop()
    })
    agent.start()
}

