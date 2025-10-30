package moe.sekiu.minilpa.agent.util

import org.apache.commons.lang3.ArchUtils
import org.apache.commons.lang3.SystemUtils

fun getPlatformInfo(): String {
    return when {
        SystemUtils.IS_OS_WINDOWS -> when {
            ArchUtils.getProcessor().is64Bit -> "windows-x86_64"
            else -> "windows-x86"
        }
        SystemUtils.IS_OS_MAC -> when {
            SystemUtils.OS_ARCH == "aarch64" -> "macos-aarch64"
            else -> "macos-x86_64"
        }
        SystemUtils.IS_OS_LINUX -> when {
            ArchUtils.getProcessor().is64Bit -> "linux-x86_64"
            else -> "linux-x86"
        }
        else -> "unknown"
    }
}

fun getAppDataFolder(isPackaged: Boolean = false): java.io.File {
    val userHome = System.getProperty("user.home") ?: "."
    return if (isPackaged) {
        java.io.File(userHome, ".minilpa")
    } else {
        java.io.File(".")
    }
}

