package moe.sekiu.minilpa.web.config

import org.springframework.boot.context.properties.ConfigurationProperties

@ConfigurationProperties(prefix = "minilpa")
class BackendProperties {
    var command: Command = Command()
    var cache: Cache = Cache()

    class Command {
        var timeoutMs: Long = 30_000
        var downloadTimeoutMs: Long = 120_000
        var retries: Int = 2
    }

    class Cache {
        var profilesTtlMs: Long = 2_000
        var notificationsTtlMs: Long = 2_000
        var chipInfoTtlMs: Long = 5_000
    }
}


