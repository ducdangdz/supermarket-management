package com.smartmarket.hrm.common;

import java.time.LocalDateTime;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.server.ResponseStatusException;

@RestControllerAdvice
public class ApiExceptionHandler {
    private static final org.slf4j.Logger log = org.slf4j.LoggerFactory.getLogger(ApiExceptionHandler.class);
    @ExceptionHandler(org.springframework.web.bind.MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, Object>> validationError(org.springframework.web.bind.MethodArgumentNotValidException ex) {
        return ResponseEntity.badRequest().body(Map.of("timestamp", LocalDateTime.now().toString(),
                "message", "Thông tin chưa hợp lệ. Kiểm tra email, mật khẩu (ít nhất 8 ký tự) và mã xác nhận 6 số."));
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<Map<String, Object>> badRequest(IllegalArgumentException ex) {
        return ResponseEntity.badRequest().body(Map.of("timestamp", LocalDateTime.now().toString(), "message", ex.getMessage()));
    }

    @ExceptionHandler(ResponseStatusException.class)
    public ResponseEntity<Map<String, Object>> responseStatus(ResponseStatusException ex) {
        return ResponseEntity.status(ex.getStatusCode()).body(Map.of(
                "timestamp", LocalDateTime.now().toString(),
                "message", ex.getReason() == null ? "Yêu cầu không hợp lệ." : ex.getReason()));
    }

    @ExceptionHandler(IllegalStateException.class)
    public ResponseEntity<Map<String, Object>> configurationError(IllegalStateException ex) {
        return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE).body(Map.of(
                "timestamp", LocalDateTime.now().toString(), "message", ex.getMessage()));
    }

    @ExceptionHandler(org.springframework.dao.DataIntegrityViolationException.class)
    public ResponseEntity<Map<String,Object>> conflict(org.springframework.dao.DataIntegrityViolationException ex) {
        return ResponseEntity.status(HttpStatus.CONFLICT).body(Map.of("timestamp",LocalDateTime.now().toString(),
            "message","Dữ liệu bị trùng hoặc không đáp ứng ràng buộc. Kiểm tra mã, email và dữ liệu liên quan."));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, Object>> serverError(Exception ex) {
        // Log diagnostic codes only: SQL messages can contain user or connection data.
        Throwable cause = ex;
        for (int depth = 0; depth < 20 && cause != null; depth++) {
            if (cause instanceof java.sql.SQLException sql) {
                log.error("Database failure: type={}, SQLState={}, vendorCode={}",
                        sql.getClass().getSimpleName(), sql.getSQLState(), sql.getErrorCode());
            }
            if (cause.getCause() == cause) break;
            cause = cause.getCause();
        }
        log.error("Request failed: type={}", ex.getClass().getSimpleName());
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
                "timestamp", LocalDateTime.now().toString(),
                "message", "Máy chủ gặp lỗi. Hãy kiểm tra kết nối database hoặc nhật ký backend."));
    }
}

