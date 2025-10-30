package moe.sekiu.minilpa.web.config

import moe.sekiu.minilpa.web.model.ApiResponse
import org.slf4j.LoggerFactory
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.MethodArgumentNotValidException
import org.springframework.web.bind.annotation.ExceptionHandler
import org.springframework.web.bind.annotation.RestControllerAdvice

@RestControllerAdvice
class GlobalExceptionHandler {

    private val log = LoggerFactory.getLogger(javaClass)

    @ExceptionHandler(IllegalArgumentException::class)
    fun handleBadRequest(e: IllegalArgumentException): ResponseEntity<ApiResponse<Unit>> {
        log.warn("Bad request: ${e.message}")
        return ResponseEntity
            .status(HttpStatus.BAD_REQUEST)
            .body(ApiResponse(success = false, error = e.message ?: "参数错误", code = "BAD_REQUEST"))
    }

    @ExceptionHandler(MethodArgumentNotValidException::class)
    fun handleValidation(e: MethodArgumentNotValidException): ResponseEntity<ApiResponse<Unit>> {
        val msg = e.bindingResult.fieldErrors.joinToString(", ") { "${it.field}:${it.defaultMessage}" }
        log.warn("Validation failed: $msg")
        return ResponseEntity
            .status(HttpStatus.BAD_REQUEST)
            .body(ApiResponse(success = false, error = msg, code = "VALIDATION_ERROR"))
    }

    @ExceptionHandler(Exception::class)
    fun handleOther(e: Exception): ResponseEntity<ApiResponse<Unit>> {
        log.error("Unhandled exception", e)
        return ResponseEntity
            .status(HttpStatus.INTERNAL_SERVER_ERROR)
            .body(ApiResponse(success = false, error = e.message ?: "服务器内部错误", code = "INTERNAL_ERROR"))
    }
}


