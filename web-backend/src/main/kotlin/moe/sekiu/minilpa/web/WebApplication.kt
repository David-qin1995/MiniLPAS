package moe.sekiu.minilpa.web

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.runApplication
import org.springframework.boot.context.properties.EnableConfigurationProperties
import moe.sekiu.minilpa.web.config.BackendProperties

@SpringBootApplication
@EnableConfigurationProperties(BackendProperties::class)
class WebApplication

fun main(args: Array<String>) {
    runApplication<WebApplication>(*args)
}

