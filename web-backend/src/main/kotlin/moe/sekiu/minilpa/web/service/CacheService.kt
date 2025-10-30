package moe.sekiu.minilpa.web.service

import com.github.benmanes.caffeine.cache.Caffeine
import moe.sekiu.minilpa.web.config.BackendProperties
import org.springframework.stereotype.Service
import java.time.Duration

@Service
class CacheService(
    private val props: BackendProperties
) {
    private val profilesCache = Caffeine.newBuilder()
        .maximumSize(200)
        .expireAfterWrite(Duration.ofMillis(props.cache.profilesTtlMs))
        .recordStats()
        .build<String, Any>()

    private val notificationsCache = Caffeine.newBuilder()
        .maximumSize(200)
        .expireAfterWrite(Duration.ofMillis(props.cache.notificationsTtlMs))
        .recordStats()
        .build<String, Any>()

    private val chipInfoCache = Caffeine.newBuilder()
        .maximumSize(100)
        .expireAfterWrite(Duration.ofMillis(props.cache.chipInfoTtlMs))
        .recordStats()
        .build<String, Any>()

    @Suppress("UNCHECKED_CAST")
    fun <T> get(key: String): T? {
        return when {
            key.startsWith("profiles:") -> profilesCache.getIfPresent(key) as T?
            key.startsWith("notifications:") -> notificationsCache.getIfPresent(key) as T?
            key.startsWith("chipinfo:") -> chipInfoCache.getIfPresent(key) as T?
            else -> null
        }
    }

    fun <T> put(key: String, value: T, @Suppress("UNUSED_PARAMETER") ttlMs: Long) {
        when {
            key.startsWith("profiles:") -> profilesCache.put(key, value as Any)
            key.startsWith("notifications:") -> notificationsCache.put(key, value as Any)
            key.startsWith("chipinfo:") -> chipInfoCache.put(key, value as Any)
        }
    }

    fun invalidate(key: String) {
        when {
            key.startsWith("profiles:") -> profilesCache.invalidate(key)
            key.startsWith("notifications:") -> notificationsCache.invalidate(key)
            key.startsWith("chipinfo:") -> chipInfoCache.invalidate(key)
        }
    }

    fun invalidateByPrefix(prefix: String) {
        when (prefix) {
            "profiles:" -> profilesCache.invalidateAll()
            "notifications:" -> notificationsCache.invalidateAll()
            "chipinfo:" -> chipInfoCache.invalidateAll()
        }
    }
}


