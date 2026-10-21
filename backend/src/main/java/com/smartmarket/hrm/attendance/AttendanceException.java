package com.smartmarket.hrm.attendance;

/**
 * Lỗi vi phạm business rule chấm công.
 * {@code code} là mã cố định (ví dụ QR_EXPIRED, INVALID_LOCATION) để app Flutter hiển thị đúng lý do từ chối;
 * {@code message} là câu thông báo tiếng Việt cho người dùng.
 */
public class AttendanceException extends RuntimeException {
    private final String code;

    public AttendanceException(String code, String message) {
        super(message);
        this.code = code;
    }

    public String code() {
        return code;
    }
}
