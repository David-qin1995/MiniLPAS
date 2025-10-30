package moe.sekiu.minilpa.web.config

import org.slf4j.LoggerFactory
import org.springframework.boot.ApplicationArguments
import org.springframework.boot.ApplicationRunner
import org.springframework.core.env.Environment
import org.springframework.stereotype.Component
import java.nio.file.Files
import java.nio.file.Paths

@Component
class StartupValidation(
    private val env: Environment
) : ApplicationRunner {

    private val log = LoggerFactory.getLogger(javaClass)

    override fun run(args: ApplicationArguments) {
        val port = env.getProperty("server.port", "8080")
        log.info("backend_startup port={}", port)

        val logFile = env.getProperty("logging.file.name", "./logs/backend.log")
        try {
            val path = Paths.get(logFile).toAbsolutePath().parent
            if (path != null && !Files.exists(path)) {
                Files.createDirectories(path)
            }
            log.info("log_path_ready path={}", path)
        } catch (e: Exception) {
            log.warn("log_path_prepare_failed path={} error={}", logFile, e.message)
        }
    }
}


