package com.smartmarket.hrm.attendance;

import com.smartmarket.hrm.auth.AccessControl;
import com.smartmarket.hrm.auth.CurrentUser;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.sql.Time;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.Base64;
import java.util.List;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api")
public class AttendanceController {
    private static final SecureRandom RANDOM = new SecureRandom();
    private final JdbcTemplate jdbc;
    private final AccessControl access;

    public AttendanceController(JdbcTemplate jdbc, AccessControl access) {
        this.jdbc = jdbc;
        this.access = access;
    }

    @PostMapping("/management/qr-sessions")
    public ResponseEntity<QrSessionResponse> createQrSession(@Valid @RequestBody QrSessionRequest body, HttpServletRequest request) {
        requireCount("SELECT COUNT(*) FROM dbo.shifts WHERE shift_id = ? AND is_active = 1", body.shiftId(), "Ca làm không tồn tại.");
        requireCount("SELECT COUNT(*) FROM dbo.work_areas WHERE work_area_id = ? AND is_active = 1", body.workAreaId(), "Khu vực không tồn tại.");
        if (!List.of("CHECK_IN", "CHECK_OUT").contains(body.sessionType())) throw new IllegalArgumentException("sessionType phải là CHECK_IN hoặc CHECK_OUT.");
        if (body.expiresInSeconds() < 30 || body.expiresInSeconds() > 300) throw new IllegalArgumentException("QR chỉ được có thời hạn từ 30 đến 300 giây.");

        byte[] randomBytes = new byte[32];
        RANDOM.nextBytes(randomBytes);
        String token = Base64.getUrlEncoder().withoutPadding().encodeToString(randomBytes);
        LocalDateTime expiry = LocalDateTime.now().plusSeconds(body.expiresInSeconds());
        CurrentUser current = access.current(request);
        jdbc.update("""
                INSERT INTO dbo.qr_sessions (shift_id, work_area_id, session_type, token_hash, expires_at, issued_by)
                VALUES (?, ?, ?, ?, ?, ?)
                """, body.shiftId(), body.workAreaId(), body.sessionType(), sha256(token), expiry, current.employeeId());
        return ResponseEntity.status(HttpStatus.CREATED).body(new QrSessionResponse(token, expiry, body.sessionType()));
    }

    @PostMapping("/attendance/check-in")
    @Transactional
    public ResponseEntity<AttendanceResponse> checkIn(@Valid @RequestBody CheckInRequest body, HttpServletRequest request) {
        access.requireSelfOrStaff(request, body.employeeId());
        Map<String, Object> schedule = schedule(body.scheduleId(), body.employeeId());
        if (!"SCHEDULED".equals(schedule.get("schedule_status"))) throw new IllegalArgumentException("Lịch làm này không còn hiệu lực.");
        if (jdbc.queryForObject("SELECT COUNT(*) FROM dbo.attendance_records WHERE schedule_id = ?", Integer.class, body.scheduleId()) > 0)
            throw new IllegalArgumentException("Lịch làm này đã được check-in.");

        Long qrId = validateQr(schedule, "CHECK_IN", body.qrToken());
        LocalDateTime now = LocalDateTime.now();
        LocalDate workDate = ((java.sql.Date) schedule.get("work_date")).toLocalDate();
        LocalTime shiftStart = ((Time) schedule.get("start_time")).toLocalTime();
        int allowedLate = ((Number) schedule.get("allowed_late_minutes")).intValue();
        String status = now.isAfter(LocalDateTime.of(workDate, shiftStart).plusMinutes(allowedLate)) ? "LATE" : "PRESENT";

        jdbc.update("""
                INSERT INTO dbo.attendance_records
                (schedule_id, employee_id, check_in_qr_session_id, check_in_at, check_in_latitude, check_in_longitude, check_in_accuracy_meters, attendance_status, verification_status)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'VERIFIED')
                """, body.scheduleId(), body.employeeId(), qrId, now, body.latitude(), body.longitude(), body.accuracyMeters(), status);
        return ResponseEntity.status(HttpStatus.CREATED).body(new AttendanceResponse(body.scheduleId(), now, status, "Check-in thành công."));
    }

    @PostMapping("/attendance/check-out")
    @Transactional
    public AttendanceResponse checkOut(@Valid @RequestBody CheckOutRequest body, HttpServletRequest request) {
        access.requireSelfOrStaff(request, body.employeeId());
        Map<String, Object> schedule = schedule(body.scheduleId(), body.employeeId());
        Map<String, Object> attendance = jdbc.queryForMap("""
                SELECT attendance_id, check_in_at, check_out_at FROM dbo.attendance_records
                WHERE schedule_id = ? AND employee_id = ?
                """, body.scheduleId(), body.employeeId());
        if (attendance.get("check_in_at") == null) throw new IllegalArgumentException("Cần check-in trước khi check-out.");
        if (attendance.get("check_out_at") != null) throw new IllegalArgumentException("Lịch làm này đã check-out.");
        Long qrId = validateQr(schedule, "CHECK_OUT", body.qrToken());
        LocalDateTime now = LocalDateTime.now();
        jdbc.update("""
                UPDATE dbo.attendance_records
                SET check_out_qr_session_id = ?, check_out_at = ?, check_out_latitude = ?, check_out_longitude = ?, check_out_accuracy_meters = ?
                WHERE attendance_id = ?
                """, qrId, now, body.latitude(), body.longitude(), body.accuracyMeters(), attendance.get("attendance_id"));
        return new AttendanceResponse(body.scheduleId(), now, "CHECKED_OUT", "Check-out thành công.");
    }

    @GetMapping("/attendance/employees/{employeeId}/history")
    public List<Map<String, Object>> history(@PathVariable Long employeeId, HttpServletRequest request) {
        access.requireSelfOrStaff(request, employeeId);
        return jdbc.queryForList("""
                SELECT ar.attendance_id, ws.work_date, sh.shift_name, wa.area_name,
                       ar.check_in_at, ar.check_out_at, ar.attendance_status, ar.verification_status
                FROM dbo.attendance_records ar
                JOIN dbo.work_schedules ws ON ws.schedule_id = ar.schedule_id
                JOIN dbo.shifts sh ON sh.shift_id = ws.shift_id
                JOIN dbo.work_areas wa ON wa.work_area_id = ws.work_area_id
                WHERE ar.employee_id = ?
                ORDER BY ws.work_date DESC, ar.check_in_at DESC
                """, employeeId);
    }

    private Map<String, Object> schedule(Long scheduleId, Long employeeId) {
        List<Map<String, Object>> records = jdbc.queryForList("""
                SELECT ws.schedule_status, ws.work_date, ws.shift_id, ws.work_area_id,
                       sh.start_time, sh.allowed_late_minutes, sh.require_qr
                FROM dbo.work_schedules ws
                JOIN dbo.shifts sh ON sh.shift_id = ws.shift_id
                WHERE ws.schedule_id = ? AND ws.employee_id = ?
                """, scheduleId, employeeId);
        if (records.isEmpty()) throw new IllegalArgumentException("Không tìm thấy lịch làm của nhân viên.");
        return records.getFirst();
    }

    private Long validateQr(Map<String, Object> schedule, String type, String token) {
        boolean required = (Boolean) schedule.get("require_qr");
        if (!required) return null;
        if (token == null || token.isBlank()) throw new IllegalArgumentException("Ca làm yêu cầu mã QR.");
        List<Long> sessions = jdbc.query("""
                SELECT qr_session_id FROM dbo.qr_sessions
                WHERE shift_id = ? AND work_area_id = ? AND session_type = ?
                  AND token_hash = ? AND expires_at > SYSDATETIME() AND is_revoked = 0
                """, (rs, row) -> rs.getLong(1), schedule.get("shift_id"), schedule.get("work_area_id"), type, sha256(token));
        if (sessions.isEmpty()) throw new IllegalArgumentException("Mã QR không hợp lệ, đã hết hạn hoặc không thuộc khu vực này.");
        return sessions.getFirst();
    }

    private void requireCount(String sql, Long id, String message) {
        Integer count = jdbc.queryForObject(sql, Integer.class, id);
        if (count == null || count == 0) throw new IllegalArgumentException(message);
    }

    private String sha256(String value) {
        try {
            byte[] bytes = MessageDigest.getInstance("SHA-256").digest(value.getBytes(StandardCharsets.UTF_8));
            StringBuilder result = new StringBuilder(64);
            for (byte item : bytes) result.append(String.format("%02x", item));
            return result.toString();
        } catch (NoSuchAlgorithmException ex) {
            throw new IllegalStateException("SHA-256 không khả dụng.", ex);
        }
    }

    public record QrSessionRequest(@NotNull Long shiftId, @NotNull Long workAreaId, @NotBlank String sessionType,
            @NotNull Integer expiresInSeconds, Long issuedBy) { }
    public record QrSessionResponse(String token, LocalDateTime expiresAt, String sessionType) { }
    public record CheckInRequest(@NotNull Long scheduleId, @NotNull Long employeeId, String qrToken,
            Double latitude, Double longitude, Double accuracyMeters) { }
    public record CheckOutRequest(@NotNull Long scheduleId, @NotNull Long employeeId, String qrToken,
            Double latitude, Double longitude, Double accuracyMeters) { }
    public record AttendanceResponse(Long scheduleId, LocalDateTime occurredAt, String attendanceStatus, String message) { }
}
