package moe.sekiu.minilpa.agent.lpac

import moe.sekiu.minilpa.agent.model.*
import org.apache.commons.lang3.SystemUtils
import org.slf4j.LoggerFactory
import java.io.File
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.decodeFromJsonElement
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.coroutines.launch
import kotlinx.coroutines.CoroutineScope
import java.io.BufferedReader
import java.io.InputStreamReader

/**
 * LPACExecutor适配器 - 用于local-agent中执行LPAC命令
 * 这是原MiniLPA项目中LPACExecutor的简化版本，去除了UI依赖
 */
class LPACExecutor(
    private val lpacPath: File,
    private val selectedDriverEnv: String? = null
) {
    private val log = LoggerFactory.getLogger(javaClass)
    private val json = Json { ignoreUnknownKeys = true }

    suspend fun getDeviceList(): List<Driver> {
        val result = execute("driver", "apdu", "list")
        return json.decodeFromJsonElement(kotlinx.serialization.builtins.ListSerializer(Driver.serializer()), result.data)
    }

    suspend fun getChipInfo(): ChipInfo {
        val result = execute("chip", "info")
        return json.decodeFromJsonElement(ChipInfo.serializer(), result.data)
    }

    suspend fun getProfileList(): List<Profile> {
        val result = execute("profile", "list")
        return json.decodeFromJsonElement(kotlinx.serialization.builtins.ListSerializer(Profile.serializer()), result.data)
    }

    suspend fun downloadProfile(downloadInfo: DownloadInfo) {
        execute(*downloadInfo.toCommand())
    }

    suspend fun enableProfile(iccid: String) {
        execute("profile", "enable", iccid)
    }

    suspend fun disableProfile(iccid: String) {
        execute("profile", "disable", iccid)
    }

    suspend fun deleteProfile(iccid: String) {
        execute("profile", "delete", iccid)
    }

    suspend fun setProfileNickname(iccid: String, nickname: String) {
        execute("profile", "nickname", iccid, nickname)
    }

    suspend fun getNotificationList(): List<Notification> {
        val result = execute("notification", "list")
        return json.decodeFromJsonElement(kotlinx.serialization.builtins.ListSerializer(Notification.serializer()), result.data)
    }

    suspend fun processNotification(vararg seq: Int, remove: Boolean = false) {
        val commands = mutableListOf("notification", "process")
        if (remove) commands.add("-r")
        commands.addAll(seq.map { "$it" })
        execute(*commands.toTypedArray())
    }

    suspend fun removeNotification(vararg seq: Int) {
        execute("notification", "remove", *seq.map { "$it" }.toTypedArray())
    }

    suspend fun setDefaultSMDPAddress(address: String) {
        execute("chip", "defaultsmdp", address)
    }

    suspend fun getVersion(): String {
        val result = execute("version")
        return result.data.jsonPrimitive.content
    }

    private suspend fun execute(vararg commands: String): LPACIO.Payload.DataPayload {
        log.info("lpac command input -> ${commands.joinToString(" ")}")
        
        val lpacFile = if (lpacPath.isDirectory) {
            File(lpacPath, if (SystemUtils.IS_OS_WINDOWS) "lpac.exe" else "lpac")
        } else {
            lpacPath
        }
        
        if (!lpacFile.exists() || lpacFile.isDirectory) {
            throw RuntimeException("LPAC executable not found: ${lpacFile.canonicalPath}")
        }

        var lpacout: LPACIO? = null
        val processBuilder = ProcessBuilder(*(arrayOf(lpacFile.canonicalPath) + commands))
        
        // 设置环境变量
        val processEnv = processBuilder.environment()
        selectedDriverEnv?.let { processEnv["DRIVER_IFID"] = it }
        
        processBuilder.redirectErrorStream(false)
        
        return withContext(Dispatchers.IO) {
            val process = processBuilder.start()
            
            // 读取stdout
            val stdoutReader = BufferedReader(InputStreamReader(process.inputStream))
            val stderrReader = BufferedReader(InputStreamReader(process.errorStream))
            
            try {
                // 异步读取stderr
                val stderrJob = CoroutineScope(Dispatchers.IO).launch {
                    stderrReader.lineSequence().forEach { line ->
                        if (line.isNotBlank()) {
                            log.warn("lpac stderr output -> $line")
                        }
                    }
                }
                
                // 读取stdout
                stdoutReader.lineSequence().forEach { line ->
                    if (line.isBlank()) return@forEach
                    log.info("lpac stdout output -> $line")
                    try {
                        val lpacio = json.decodeFromString<LPACIO>(line)
                        when (lpacio.type) {
                            LPACIO.Type.PROGRESS -> {
                                log.debug("Progress: ${lpacio.payload.lpa.message}")
                            }
                            LPACIO.Type.LPA -> {
                                lpacout = lpacio
                            }
                            LPACIO.Type.DRIVER -> {
                                lpacout = lpacio
                            }
                            else -> log.warn("Unknown LPACIO type: ${lpacio.type}")
                        }
                    } catch (e: Exception) {
                        log.debug("Failed to parse line as LPACIO: $line", e)
                    }
                }
                
                stderrJob.join()
                process.waitFor()
            } finally {
                stdoutReader.close()
                stderrReader.close()
                process.destroy()
            }
            
            val payload = lpacout?.payload
                ?: throw RuntimeException("LPAC output not captured")
            
            if (payload is LPACIO.Payload.LPA) {
                payload.assertSuccess()
            }
            
            payload as LPACIO.Payload.DataPayload
        }
    }
}

