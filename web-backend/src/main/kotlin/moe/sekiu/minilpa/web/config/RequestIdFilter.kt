package moe.sekiu.minilpa.web.config

import jakarta.servlet.Filter
import jakarta.servlet.FilterChain
import jakarta.servlet.ServletRequest
import jakarta.servlet.ServletResponse
import jakarta.servlet.http.HttpServletRequest
import jakarta.servlet.http.HttpServletResponse
import org.slf4j.MDC
import org.springframework.core.annotation.Order
import org.springframework.stereotype.Component
import java.util.UUID

@Component
@Order(1)
class RequestIdFilter : Filter {
    override fun doFilter(request: ServletRequest, response: ServletResponse, chain: FilterChain) {
        val httpReq = request as? HttpServletRequest
        val httpResp = response as? HttpServletResponse
        val ridHeader = httpReq?.getHeader("X-Request-Id")
        val rid = ridHeader?.ifBlank { null } ?: UUID.randomUUID().toString()
        MDC.put("requestId", rid)
        try {
            httpResp?.setHeader("X-Request-Id", rid)
            chain.doFilter(request, response)
        } finally {
            MDC.remove("requestId")
        }
    }
}


