package moe.sekiu.minilpa.web.util

import kotlin.math.min

object RetryUtils {
    fun <T> retry(
        times: Int = 3,
        initialDelayMs: Long = 300,
        maxDelayMs: Long = 3_000,
        factor: Double = 2.0,
        block: () -> T
    ): T {
        var attempt = 0
        var delay = initialDelayMs
        var lastError: Throwable? = null
        while (attempt < times) {
            try {
                return block()
            } catch (e: Throwable) {
                lastError = e
                attempt++
                if (attempt >= times) break
                try {
                    Thread.sleep(delay)
                } catch (_: InterruptedException) { /* ignore */ }
                delay = min((delay * factor).toLong(), maxDelayMs)
            }
        }
        throw lastError ?: IllegalStateException("unknown error")
    }
}


