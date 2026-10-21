package com.smartmarket.hrm.attendance;

import com.smartmarket.hrm.auth.AccessControl;
import com.smartmarket.hrm.auth.CurrentUser;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.sql.Time;
import java.sql.Timestamp;
import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.OffsetDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.Base64;
import java.util.List;
import java.util.Map;
import java.security.SecureRandom;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

/**
 * API nghiệp vụ chấm công bằng QR + GPS + ảnh bằng chứng.
 *
 * <p>Thứ tự kiểm tra khi check-in/check-out:
 * <ol>
 *   <li>QR: tồn tại, chưa bị thu hồi, còn hạn, đúng loại CHECK_IN/CHECK_OUT.</li>
 *   <li>Lịch làm: nhân viên có lịch hôm nay, đúng ca, đúng khu vực của QR (sai khu vực → INVALID_LOCATION).</li>
 *   <li>Trạng thái: chưa check-in mới được check-in; đã check-in mới được check-out.</li>
 *   <li>Giờ vào: không quá sớm; quá {@code allowed_late_minutes} → LATE, ngược lại PRESENT.</li>
 *   <li>GPS (nếu ca yêu cầu): có tọa độ, sai số chấp nhận được, nằm trong bán kính khu vực.</li>
 *   <li>Ảnh bằng chứng (nếu ca yêu cầu): đã upload qua {@code POST /api/attendance/evidence} và chưa từng dùng.</li>
 * </ol>
 * Vi phạm bất kỳ bước nào ném {@link AttendanceException} kèm mã lỗi; giao dịch bị rollback nên không lưu gì.
 */
@RestController
@RequestMapping("/api")
public class AttendanceController {
    private static final SecureRandom RANDOM = new SecureRandom();
    /** Bán kính mặc định khi khu vực chưa cấu hình radius_meters. */
    private static final int DEFAULT_RADIUS_METERS = 100;
    /** GPS có sai số lớn hơn ngưỡng này bị coi là không đáng tin cậy. */
    private static final double MAX_ACCURACY_METERS = 100;
    private static final String CHECK_IN = "CHECK_IN";
    private static final String CHECK_OUT = "CHECK_OUT";

    /** Lịch làm kèm thông tin ca, khu vực và tọa độ (lấy tọa độ chi nhánh nếu khu vực chưa có). */
    private static final String SCHEDULE_SQL = """
            SELECT ws.schedule_id, ws.employee_id, ws.schedule_status, ws.work_date, ws.shift_id, ws.work_area_id,
                   sh.shift_name, sh.start_time, sh.end_time, sh.check_in_early_minutes, sh.allowed_late_minutes,
                   sh.require_qr, sh.require_location, sh.require_evidence,
                   wa.area_name, fp.floor_name, wa.radius_meters,
                   COALESCE(wa.latitude, b.latitude) AS area_latitude,
                   COALESCE(wa.longitude, b.longitude) AS area_longitude
            FROM dbo.work_schedules ws
            JOIN dbo.shifts sh ON sh.shift_id = ws.shift_id
            JOIN dbo.work_areas wa ON wa.work_area_id = ws.work_area_id
            JOIN dbo.floor_plans fp ON fp.floor_plan_id = wa.floor_plan_id
            JOIN dbo.branches b ON b.branch_id = fp.branch_id
            """;

    private final JdbcTemplate jdbc;
    private final AccessControl access;
    private final EvidenceStorage storage;

    public AttendanceController(JdbcTemplate jdbc, AccessControl access, EvidenceStorage storage) {
        this.jdbc = jdbc;
        this.access = access;
        this.storage = storage;
    }

    @PostMapping("/management/qr-sessions")
    public ResponseEntity<QrSessionResponse> createQrSession(@Valid @RequestBody QrSessionRequest body, HttpServletRequest request) {
        requireCount("SELECT COUNT(*) FROM dbo.shifts WHERE shift_id = ? AND is_active = 1", body.shiftId(), "Ca làm không tồn tại.");
        requireCount("SELECT COUNT(*) FROM dbo.work_areas WHERE work_area_id = ? AND is_active = 1", body.workAreaId(), "Khu vực không tồn tại.");
        if (!List.of(CHECK_IN, CHECK_OUT).contains(body.sessionType())) throw new IllegalArgumentException("sessionType phải là CHECK_IN hoặc CHECK_OUT.");
        if (body.expiresInSeconds() < 30 || body.expiresInSeconds() > 300) throw new IllegalArgumentException("QR chỉ được có thời hạn từ 30 đến 300 giây.");

        byte[] randomBytes = new byte[32];
        RANDOM.nextBytes(randomBytes);
        String token = Base64.getUrlEncoder().withoutPadding().encodeToString(randomBytes);
        LocalDateTime expiry = LocalDateTime.now().plusSeconds(body.expiresInSeconds());
        CurrentUser current = access.current(request);
        jdbc.update("""
                INSERT INTO dbo.qr_sessions (shift_id, work_area_id, session_type, token_hash, expires_at, issued_by)
                VALUES (?, ?, ?, ?, ?, ?)
                """, body.shiftId(), body.workAreaId(), body.sessionType(), EvidenceStorage.sha256Hex(token), expiry, current.employeeId());
        return ResponseEntity.status(HttpStatus.CREATED).body(new QrSessionResponse(token, expiry, body.sessionType()));
    }

    /** Lịch làm hôm nay của người đang đăng nhập, kèm yêu cầu QR/GPS/ảnh và trạng thái chấm công. */
    @GetMapping("/attendance/me/today")
    public List<TodayScheduleResponse> today(HttpServletRequest request) {
        CurrentUser current = access.current(request);
        return jdbc.queryForList("""
                SELECT s.*, ar.attendance_id, ar.attendance_status, ar.check_in_at, ar.check_out_at
                FROM (%s) s
                LEFT JOIN dbo.attendance_records ar ON ar.schedule_id = s.schedule_id
                WHERE s.employee_id = ? AND s.work_date = ? AND s.schedule_status = 'SCHEDULED'
                ORDER BY s.start_time
                """.formatted(SCHEDULE_SQL), current.employeeId(), LocalDate.now())
                .stream()
                .map(row -> new TodayScheduleResponse(
                        id(row.get("schedule_id")), toLocalDate(row.get("work_date")),
                        id(row.get("shift_id")), (String) row.get("shift_name"),
                        ((Time) row.get("start_time")).toLocalTime(), ((Time) row.get("end_time")).toLocalTime(),
                        intOr(row.get("allowed_late_minutes"), 15),
                        id(row.get("work_area_id")), (String) row.get("area_name"), (String) row.get("floor_name"),
                        flag(row.get("require_qr")), flag(row.get("require_location")), flag(row.get("require_evidence")),
                        (String) row.get("attendance_status"),
                        toDateTime(row.get("check_in_at")), toDateTime(row.get("check_out_at"))))
                .toList();
    }

    /** Upload ảnh bằng chứng (multipart, field "file"). Trả về fileHash để gửi kèm khi check-in/check-out. */
    @PostMapping(value = "/attendance/evidence", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<EvidenceStorage.StoredEvidence> uploadEvidence(@RequestParam("file") MultipartFile file, HttpServletRequest request) {
        access.current(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(storage.store(file));
    }

    @PostMapping("/attendance/check-in")
    @Transactional
    public ResponseEntity<AttendanceResponse> checkIn(@Valid @RequestBody AttendanceRequest body, HttpServletRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(process(CHECK_IN, body, request));
    }

    @PostMapping("/attendance/check-out")
    @Transactional
    public AttendanceResponse checkOut(@Valid @RequestBody AttendanceRequest body, HttpServletRequest request) {
        return process(CHECK_OUT, body, request);
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

    // ─── Nghiệp vụ chính ────────────────────────────────────────────────────────

    private AttendanceResponse process(String type, AttendanceRequest body, HttpServletRequest request) {
        CurrentUser current = access.current(request);
        // employeeId có thể bỏ trống: mặc định là người đang đăng nhập.
        Long employeeId = body.employeeId() == null ? current.employeeId() : body.employeeId();
        access.requireSelfOrStaff(request, employeeId);
        LocalDateTime now = LocalDateTime.now();

        QrSession qr = findQr(body.qrToken(), type, now);
        Map<String, Object> schedule = resolveSchedule(employeeId, body.scheduleId(), qr, now.toLocalDate(), type);
        if (flag(schedule.get("require_qr")) && qr == null) {
            throw new AttendanceException("QR_REQUIRED", "Ca làm này yêu cầu quét mã QR.");
        }
        Long scheduleId = id(schedule.get("schedule_id"));
        List<Map<String, Object>> existing = jdbc.queryForList(
                "SELECT attendance_id, check_in_at, check_out_at, attendance_status FROM dbo.attendance_records WHERE schedule_id = ?",
                scheduleId);
        if (CHECK_IN.equals(type) && !existing.isEmpty()) {
            throw new AttendanceException("ALREADY_CHECKED_IN", "Bạn đã check-in ca làm này rồi.");
        }
        if (CHECK_OUT.equals(type)) {
            if (existing.isEmpty() || existing.getFirst().get("check_in_at") == null) {
                throw new AttendanceException("NOT_CHECKED_IN", "Bạn chưa check-in nên không thể check-out.");
            }
            if (existing.getFirst().get("check_out_at") != null) {
                throw new AttendanceException("ALREADY_CHECKED_OUT", "Bạn đã check-out ca làm này rồi.");
            }
        }

        // Giờ vào: tính trước GPS/ảnh để báo "quá sớm" ngay, không bắt người dùng chụp ảnh vô ích.
        LocalDateTime shiftStart = LocalDateTime.of(toLocalDate(schedule.get("work_date")), ((Time) schedule.get("start_time")).toLocalTime());
        long lateMinutes = 0;
        String status = existing.isEmpty() ? null : (String) existing.getFirst().get("attendance_status");
        if (CHECK_IN.equals(type)) {
            int earlyMinutes = intOr(schedule.get("check_in_early_minutes"), 30);
            if (now.isBefore(shiftStart.minusMinutes(earlyMinutes))) {
                throw new AttendanceException("CHECK_IN_TOO_EARLY",
                        "Chỉ được check-in sớm nhất %d phút trước giờ bắt đầu ca (%s).".formatted(earlyMinutes, shiftStart.toLocalTime()));
            }
            int allowedLate = intOr(schedule.get("allowed_late_minutes"), 15);
            lateMinutes = Math.max(0, Duration.between(shiftStart, now).toMinutes());
            status = now.isAfter(shiftStart.plusMinutes(allowedLate)) ? "LATE" : "PRESENT";
        }

        Double distance = checkLocation(schedule, body);
        String evidenceUrl = checkEvidence(schedule, body);
        String note = buildNote(type, body);

        Long attendanceId;
        if (CHECK_IN.equals(type)) {
            jdbc.update("""
                    INSERT INTO dbo.attendance_records
                    (schedule_id, employee_id, check_in_qr_session_id, check_in_at, check_in_latitude, check_in_longitude,
                     check_in_accuracy_meters, attendance_status, verification_status, note)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """, scheduleId, employeeId, qr == null ? null : qr.id(), now, body.latitude(), body.longitude(),
                    body.accuracyMeters(), status, evidenceUrl == null ? "VERIFIED" : "PENDING", note);
            attendanceId = jdbc.queryForObject("SELECT attendance_id FROM dbo.attendance_records WHERE schedule_id = ?", Long.class, scheduleId);
        } else {
            attendanceId = id(existing.getFirst().get("attendance_id"));
            jdbc.update("""
                    UPDATE dbo.attendance_records
                    SET check_out_qr_session_id = ?, check_out_at = ?, check_out_latitude = ?, check_out_longitude = ?,
                        check_out_accuracy_meters = ?, updated_at = SYSDATETIME()
                    WHERE attendance_id = ?
                    """, qr == null ? null : qr.id(), now, body.latitude(), body.longitude(), body.accuracyMeters(), attendanceId);
            if (note != null) {
                // Nối ghi chú check-out vào sau ghi chú check-in (cột note tối đa 500 ký tự).
                jdbc.update("""
                        UPDATE dbo.attendance_records
                        SET note = LEFT(CASE WHEN note IS NULL THEN ? ELSE CONCAT(note, ' | ', ?) END, 500)
                        WHERE attendance_id = ?
                        """, note, note, attendanceId);
            }
        }
        if (evidenceUrl != null) saveEvidence(attendanceId, type, evidenceUrl, body, now);

        String message = CHECK_OUT.equals(type) ? "Check-out thành công."
                : "LATE".equals(status) ? "Check-in thành công nhưng bạn đi muộn %d phút.".formatted(lateMinutes)
                : "Check-in thành công, bạn đến đúng giờ.";
        return new AttendanceResponse(attendanceId, scheduleId, type, now, status, lateMinutes,
                (String) schedule.get("shift_name"), (String) schedule.get("area_name"), distance, evidenceUrl, message);
    }

    /** Kiểm tra QR theo hash token; null nếu người dùng không gửi QR (ca có thể không yêu cầu QR). */
    private QrSession findQr(String token, String type, LocalDateTime now) {
        if (token == null || token.isBlank()) return null;
        List<Map<String, Object>> rows = jdbc.queryForList("""
                SELECT q.qr_session_id, q.shift_id, q.work_area_id, q.session_type, q.expires_at, q.is_revoked, wa.area_name
                FROM dbo.qr_sessions q
                JOIN dbo.work_areas wa ON wa.work_area_id = q.work_area_id
                WHERE q.token_hash = ?
                """, EvidenceStorage.sha256Hex(token.trim()));
        if (rows.isEmpty()) throw new AttendanceException("QR_INVALID", "Mã QR không hợp lệ hoặc không do hệ thống tạo.");
        Map<String, Object> row = rows.getFirst();
        if (flag(row.get("is_revoked"))) throw new AttendanceException("QR_REVOKED", "Mã QR đã bị quản lý thu hồi.");
        if (!now.isBefore(toDateTime(row.get("expires_at")))) {
            throw new AttendanceException("QR_EXPIRED", "Mã QR đã hết hạn. Hãy yêu cầu quản lý tạo mã mới.");
        }
        if (!type.equals(row.get("session_type"))) {
            throw new AttendanceException("QR_WRONG_TYPE", CHECK_IN.equals(type)
                    ? "Đây là mã QR check-out, không dùng để check-in."
                    : "Đây là mã QR check-in, không dùng để check-out.");
        }
        return new QrSession(id(row.get("qr_session_id")), id(row.get("shift_id")), id(row.get("work_area_id")), (String) row.get("area_name"));
    }

    /**
     * Xác định lịch làm cần chấm công. Nếu client không gửi scheduleId, tìm theo ca + khu vực của QR
     * trong các lịch hôm nay của nhân viên.
     */
    private Map<String, Object> resolveSchedule(Long employeeId, Long scheduleId, QrSession qr, LocalDate today, String type) {
        List<Map<String, Object>> candidates;
        if (scheduleId != null) {
            candidates = jdbc.queryForList(SCHEDULE_SQL + " WHERE ws.schedule_id = ? AND ws.employee_id = ?", scheduleId, employeeId);
            if (candidates.isEmpty()) throw new AttendanceException("NO_SCHEDULE", "Không tìm thấy lịch làm của bạn.");
            Map<String, Object> schedule = candidates.getFirst();
            if (!"SCHEDULED".equals(schedule.get("schedule_status"))) {
                throw new AttendanceException("SCHEDULE_NOT_ACTIVE", "Lịch làm này không còn hiệu lực.");
            }
            if (!today.equals(toLocalDate(schedule.get("work_date")))) {
                throw new AttendanceException("NOT_WORK_DATE", "Chỉ có thể chấm công trong ngày làm việc đã được phân công.");
            }
        } else {
            candidates = jdbc.queryForList(SCHEDULE_SQL + " WHERE ws.employee_id = ? AND ws.work_date = ? AND ws.schedule_status = 'SCHEDULED' ORDER BY sh.start_time",
                    employeeId, today);
            if (candidates.isEmpty()) {
                throw new AttendanceException("NO_SCHEDULE", CHECK_IN.equals(type)
                        ? "Hôm nay bạn không có lịch làm nên không thể check-in."
                        : "Hôm nay bạn không có lịch làm nên không thể check-out.");
            }
            if (qr == null && candidates.size() > 1) {
                throw new AttendanceException("SCHEDULE_REQUIRED", "Hôm nay bạn có nhiều ca, hãy chọn ca cần chấm công.");
            }
        }
        if (qr == null) return candidates.getFirst();

        List<Map<String, Object>> sameShift = candidates.stream().filter(s -> id(s.get("shift_id")) == qr.shiftId()).toList();
        if (sameShift.isEmpty()) {
            throw new AttendanceException("WRONG_SHIFT", "Mã QR không thuộc ca làm của bạn hôm nay.");
        }
        return sameShift.stream()
                .filter(s -> id(s.get("work_area_id")) == qr.workAreaId())
                .findFirst()
                .orElseThrow(() -> new AttendanceException("INVALID_LOCATION",
                        "Mã QR thuộc khu vực \"%s\" nhưng bạn được phân công ở \"%s\"."
                                .formatted(qr.areaName(), sameShift.getFirst().get("area_name"))));
    }

    /** Kiểm tra GPS khi ca yêu cầu; trả về khoảng cách tới khu vực (mét) nếu tính được. */
    private Double checkLocation(Map<String, Object> schedule, AttendanceRequest body) {
        boolean required = flag(schedule.get("require_location"));
        if (body.latitude() == null || body.longitude() == null) {
            if (required) throw new AttendanceException("LOCATION_REQUIRED", "Ca làm này yêu cầu bật vị trí GPS khi chấm công.");
            return null;
        }
        Double areaLat = dbl(schedule.get("area_latitude"));
        Double areaLng = dbl(schedule.get("area_longitude"));
        Double distance = areaLat == null || areaLng == null ? null
                : Math.round(distanceMeters(body.latitude(), body.longitude(), areaLat, areaLng) * 10) / 10.0;
        if (!required) return distance;

        if (body.accuracyMeters() != null && body.accuracyMeters() > MAX_ACCURACY_METERS) {
            throw new AttendanceException("GPS_INACCURATE",
                    "Tín hiệu GPS chưa đủ chính xác (sai số %.0f m). Hãy ra chỗ thoáng và thử lại.".formatted(body.accuracyMeters()));
        }
        int radius = intOr(schedule.get("radius_meters"), DEFAULT_RADIUS_METERS);
        if (distance != null && distance > radius) {
            throw new AttendanceException("INVALID_LOCATION",
                    "Bạn đang cách khu vực \"%s\" khoảng %.0f m (cho phép %d m).".formatted(schedule.get("area_name"), distance, radius));
        }
        return distance;
    }

    /** Kiểm tra ảnh bằng chứng; trả về URL ảnh nếu có. */
    private String checkEvidence(Map<String, Object> schedule, AttendanceRequest body) {
        String hash = body.evidence() == null ? null : body.evidence().fileHash();
        if (hash == null || hash.isBlank()) {
            if (flag(schedule.get("require_evidence"))) {
                throw new AttendanceException("EVIDENCE_REQUIRED", "Ca làm này yêu cầu ảnh bằng chứng. Hãy chụp ảnh trước khi hoàn tất.");
            }
            return null;
        }
        String url = storage.findUrl(hash.trim()).orElseThrow(() ->
                new AttendanceException("EVIDENCE_NOT_FOUND", "Không tìm thấy ảnh bằng chứng đã upload. Hãy chụp lại."));
        Integer used = jdbc.queryForObject("SELECT COUNT(*) FROM dbo.attendance_evidence WHERE file_hash = ?", Integer.class, hash.trim());
        if (used != null && used > 0) throw new AttendanceException("EVIDENCE_REUSED", "Ảnh này đã được dùng cho lần chấm công khác.");
        return url;
    }

    private void saveEvidence(Long attendanceId, String type, String fileUrl, AttendanceRequest body, LocalDateTime now) {
        LocalDateTime capturedAt = parseClientTime(body.evidence().capturedAt());
        jdbc.update("""
                INSERT INTO dbo.attendance_evidence
                (attendance_id, evidence_type, file_url, file_hash, captured_at, latitude, longitude, device_info)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                """, attendanceId, CHECK_IN.equals(type) ? "CHECK_IN_PHOTO" : "CHECK_OUT_PHOTO", fileUrl,
                body.evidence().fileHash().trim(), capturedAt == null ? now : capturedAt,
                body.latitude(), body.longitude(), truncate(body.deviceInfo(), 500));
    }

    /** Ghi chú lưu thông tin thiết bị và giờ trên máy (server luôn dùng giờ của server để chấm công). */
    private String buildNote(String type, AttendanceRequest body) {
        List<String> parts = new ArrayList<>();
        if (body.deviceInfo() != null && !body.deviceInfo().isBlank()) parts.add("Thiết bị: " + body.deviceInfo().trim());
        if (body.clientTime() != null && !body.clientTime().isBlank()) parts.add("Giờ máy: " + body.clientTime().trim());
        if (parts.isEmpty()) return null;
        return truncate((CHECK_IN.equals(type) ? "[Vào] " : "[Ra] ") + String.join(", ", parts), 240);
    }

    // ─── Tiện ích ───────────────────────────────────────────────────────────────

    /** Công thức Haversine: khoảng cách (mét) giữa hai tọa độ trên mặt cầu Trái Đất. */
    static double distanceMeters(double lat1, double lon1, double lat2, double lon2) {
        double earthRadius = 6_371_000;
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2)) * Math.sin(dLon / 2) * Math.sin(dLon / 2);
        return 2 * earthRadius * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    }

    private static LocalDateTime parseClientTime(String value) {
        if (value == null || value.isBlank()) return null;
        try {
            return OffsetDateTime.parse(value).atZoneSameInstant(ZoneId.systemDefault()).toLocalDateTime();
        } catch (DateTimeParseException ignored) {
            try {
                return LocalDateTime.parse(value);
            } catch (DateTimeParseException ignoredAgain) {
                return null;
            }
        }
    }

    private static long id(Object value) {
        return ((Number) value).longValue();
    }

    private static Double dbl(Object value) {
        return value == null ? null : ((Number) value).doubleValue();
    }

    private static int intOr(Object value, int fallback) {
        return value == null ? fallback : ((Number) value).intValue();
    }

    private static boolean flag(Object value) {
        return Boolean.TRUE.equals(value);
    }

    private static LocalDate toLocalDate(Object value) {
        return value instanceof java.sql.Date date ? date.toLocalDate() : (LocalDate) value;
    }

    private static LocalDateTime toDateTime(Object value) {
        if (value == null) return null;
        return value instanceof Timestamp timestamp ? timestamp.toLocalDateTime() : (LocalDateTime) value;
    }

    private static String truncate(String value, int max) {
        if (value == null) return null;
        return value.length() <= max ? value : value.substring(0, max);
    }

    private void requireCount(String sql, Long id, String message) {
        Integer count = jdbc.queryForObject(sql, Integer.class, id);
        if (count == null || count == 0) throw new IllegalArgumentException(message);
    }

    private record QrSession(Long id, long shiftId, long workAreaId, String areaName) { }

    public record QrSessionRequest(@NotNull Long shiftId, @NotNull Long workAreaId, @NotBlank String sessionType,
            @NotNull Integer expiresInSeconds, Long issuedBy) { }
    public record QrSessionResponse(String token, LocalDateTime expiresAt, String sessionType) { }

    /**
     * Dữ liệu chấm công app gửi lên. scheduleId/employeeId có thể bỏ trống (backend tự xác định theo QR
     * và người đăng nhập). clientTime là giờ trên điện thoại, chỉ để đối chiếu.
     */
    public record AttendanceRequest(Long scheduleId, Long employeeId, String qrToken,
            Double latitude, Double longitude, Double accuracyMeters,
            String clientTime, String deviceInfo, EvidenceRequest evidence) { }
    public record EvidenceRequest(String fileHash, String capturedAt) { }

    public record AttendanceResponse(Long attendanceId, Long scheduleId, String action, LocalDateTime occurredAt,
            String attendanceStatus, long lateMinutes, String shiftName, String areaName, Double distanceMeters,
            String evidenceUrl, String message) { }

    public record TodayScheduleResponse(Long scheduleId, LocalDate workDate, Long shiftId, String shiftName,
            LocalTime startTime, LocalTime endTime, int allowedLateMinutes, Long workAreaId, String areaName,
            String floorName, boolean requireQr, boolean requireLocation, boolean requireEvidence,
            String attendanceStatus, LocalDateTime checkInAt, LocalDateTime checkOutAt) { }
}
