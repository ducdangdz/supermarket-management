package com.smartmarket.hrm.attendance;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

import java.sql.Time;
import java.sql.Timestamp;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.*;

import com.smartmarket.hrm.auth.AccessControl;
import com.smartmarket.hrm.auth.CurrentUser;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mock.web.MockHttpServletRequest;

class AttendanceQrValidationTest {
    private final JdbcTemplate jdbc = mock(JdbcTemplate.class);
    private final EvidenceStorage storage = mock(EvidenceStorage.class);
    private final AccessControl access = new AccessControl();
    private AttendanceController controller;

    private static final long EMPLOYEE_ID = 10L;
    private static final long SHIFT_ID = 1L;
    private static final long AREA_ID = 2L;
    private static final String QR_TOKEN = "valid_qr_token_123";
    private static final String QR_HASH = EvidenceStorage.sha256Hex(QR_TOKEN);

    @BeforeEach
    void setUp() {
        controller = new AttendanceController(jdbc, access, storage);
    }

    private MockHttpServletRequest employeeRequest() {
        MockHttpServletRequest request = new MockHttpServletRequest();
        request.setAttribute(AccessControl.CURRENT_USER,
                new CurrentUser(EMPLOYEE_ID, "NV001", "Nguyen Van A", "a@smartmarket.com", "EMPLOYEE", "Nhân viên", 1L));
        return request;
    }

    private MockHttpServletRequest managerRequest() {
        MockHttpServletRequest request = new MockHttpServletRequest();
        request.setAttribute(AccessControl.CURRENT_USER,
                new CurrentUser(99L, "QL001", "Quan Ly", "ql@smartmarket.com", "MANAGER", "Quản lý", 1L));
        return request;
    }

    private Map<String, Object> createQrRow(long shiftId, long areaId, String type, boolean revoked, LocalDateTime expiresAt) {
        Map<String, Object> row = new HashMap<>();
        row.put("qr_session_id", 50L);
        row.put("shift_id", shiftId);
        row.put("work_area_id", areaId);
        row.put("session_type", type);
        row.put("expires_at", Timestamp.valueOf(expiresAt));
        row.put("is_revoked", revoked);
        row.put("area_name", "Khu thu ngân");
        return row;
    }

    private Map<String, Object> createScheduleRow(long shiftId, long areaId) {
        Map<String, Object> row = new HashMap<>();
        row.put("schedule_id", 100L);
        row.put("employee_id", EMPLOYEE_ID);
        row.put("schedule_status", "SCHEDULED");
        row.put("work_date", java.sql.Date.valueOf(LocalDate.now()));
        row.put("shift_id", shiftId);
        row.put("work_area_id", areaId);
        row.put("shift_name", "Ca sáng");
        row.put("start_time", Time.valueOf(LocalTime.now().minusMinutes(5)));
        row.put("end_time", Time.valueOf(LocalTime.now().plusHours(7)));
        row.put("check_in_early_minutes", 30);
        row.put("allowed_late_minutes", 15);
        row.put("require_qr", true);
        row.put("require_location", false);
        row.put("require_evidence", false);
        row.put("area_name", "Khu thu ngân");
        row.put("floor_name", "Tầng 1");
        row.put("radius_meters", 100);
        row.put("area_latitude", 10.77);
        row.put("area_longitude", 106.70);
        return row;
    }

    @Test
    void validQr_checkInSucceeds() {
        var qrRow = createQrRow(SHIFT_ID, AREA_ID, "CHECK_IN", false, LocalDateTime.now().plusSeconds(90));
        when(jdbc.queryForList(contains("FROM dbo.qr_sessions"), eq(QR_HASH))).thenReturn(List.of(qrRow));

        var scheduleRow = createScheduleRow(SHIFT_ID, AREA_ID);
        when(jdbc.queryForList(contains("WHERE ws.employee_id = ? AND ws.work_date = ?"), eq(EMPLOYEE_ID), any()))
                .thenReturn(List.of(scheduleRow));

        when(jdbc.queryForList(contains("FROM dbo.attendance_records WHERE schedule_id = ?"), eq(100L)))
                .thenReturn(Collections.emptyList());
        when(jdbc.queryForObject(contains("SELECT attendance_id FROM dbo.attendance_records"), eq(Long.class), eq(100L)))
                .thenReturn(200L);

        var requestBody = new AttendanceController.AttendanceRequest(null, EMPLOYEE_ID, QR_TOKEN, null, null, null, null, null, null);
        var response = controller.checkIn(requestBody, employeeRequest());

        assertNotNull(response);
        assertEquals(200L, response.getBody().attendanceId());
        assertEquals("CHECK_IN", response.getBody().action());
    }

    @Test
    void expiredQr_throwsQrExpired() {
        var expiredRow = createQrRow(SHIFT_ID, AREA_ID, "CHECK_IN", false, LocalDateTime.now().minusSeconds(10));
        when(jdbc.queryForList(contains("FROM dbo.qr_sessions"), eq(QR_HASH))).thenReturn(List.of(expiredRow));

        var requestBody = new AttendanceController.AttendanceRequest(null, EMPLOYEE_ID, QR_TOKEN, null, null, null, null, null, null);
        AttendanceException ex = assertThrows(AttendanceException.class, () -> controller.checkIn(requestBody, employeeRequest()));

        assertEquals("QR_EXPIRED", ex.getCode());
        assertEquals("QR đã hết hạn.", ex.getMessage());
    }

    @Test
    void revokedQr_throwsQrRevoked() {
        var revokedRow = createQrRow(SHIFT_ID, AREA_ID, "CHECK_IN", true, LocalDateTime.now().plusSeconds(90));
        when(jdbc.queryForList(contains("FROM dbo.qr_sessions"), eq(QR_HASH))).thenReturn(List.of(revokedRow));

        var requestBody = new AttendanceController.AttendanceRequest(null, EMPLOYEE_ID, QR_TOKEN, null, null, null, null, null, null);
        AttendanceException ex = assertThrows(AttendanceException.class, () -> controller.checkIn(requestBody, employeeRequest()));

        assertEquals("QR_REVOKED", ex.getCode());
        assertEquals("QR đã bị thu hồi.", ex.getMessage());
    }

    @Test
    void wrongTypeQr_checkOutUsedForCheckIn_throwsQrWrongType() {
        var checkOutQr = createQrRow(SHIFT_ID, AREA_ID, "CHECK_OUT", false, LocalDateTime.now().plusSeconds(90));
        when(jdbc.queryForList(contains("FROM dbo.qr_sessions"), eq(QR_HASH))).thenReturn(List.of(checkOutQr));

        var requestBody = new AttendanceController.AttendanceRequest(null, EMPLOYEE_ID, QR_TOKEN, null, null, null, null, null, null);
        AttendanceException ex = assertThrows(AttendanceException.class, () -> controller.checkIn(requestBody, employeeRequest()));

        assertEquals("QR_WRONG_TYPE", ex.getCode());
        assertEquals("Bạn đang dùng QR check-out để check-in.", ex.getMessage());
    }

    @Test
    void wrongTypeQr_checkInUsedForCheckOut_throwsQrWrongType() {
        var checkInQr = createQrRow(SHIFT_ID, AREA_ID, "CHECK_IN", false, LocalDateTime.now().plusSeconds(90));
        when(jdbc.queryForList(contains("FROM dbo.qr_sessions"), eq(QR_HASH))).thenReturn(List.of(checkInQr));

        var requestBody = new AttendanceController.AttendanceRequest(null, EMPLOYEE_ID, QR_TOKEN, null, null, null, null, null, null);
        AttendanceException ex = assertThrows(AttendanceException.class, () -> controller.checkOut(requestBody, employeeRequest()));

        assertEquals("QR_WRONG_TYPE", ex.getCode());
        assertEquals("Bạn đang dùng QR check-in để check-out.", ex.getMessage());
    }

    @Test
    void wrongShiftQr_throwsWrongShift() {
        long differentShiftId = 999L;
        var qrRow = createQrRow(differentShiftId, AREA_ID, "CHECK_IN", false, LocalDateTime.now().plusSeconds(90));
        when(jdbc.queryForList(contains("FROM dbo.qr_sessions"), eq(QR_HASH))).thenReturn(List.of(qrRow));

        var scheduleRow = createScheduleRow(SHIFT_ID, AREA_ID);
        when(jdbc.queryForList(contains("WHERE ws.employee_id = ? AND ws.work_date = ?"), eq(EMPLOYEE_ID), any()))
                .thenReturn(List.of(scheduleRow));

        var requestBody = new AttendanceController.AttendanceRequest(null, EMPLOYEE_ID, QR_TOKEN, null, null, null, null, null, null);
        AttendanceException ex = assertThrows(AttendanceException.class, () -> controller.checkIn(requestBody, employeeRequest()));

        assertEquals("WRONG_SHIFT", ex.getCode());
        assertEquals("QR không thuộc ca làm của bạn.", ex.getMessage());
    }

    @Test
    void wrongAreaQr_throwsInvalidLocation() {
        long differentAreaId = 888L;
        var qrRow = createQrRow(SHIFT_ID, differentAreaId, "CHECK_IN", false, LocalDateTime.now().plusSeconds(90));
        qrRow.put("area_name", "Kho hàng");
        when(jdbc.queryForList(contains("FROM dbo.qr_sessions"), eq(QR_HASH))).thenReturn(List.of(qrRow));

        var scheduleRow = createScheduleRow(SHIFT_ID, AREA_ID);
        when(jdbc.queryForList(contains("WHERE ws.employee_id = ? AND ws.work_date = ?"), eq(EMPLOYEE_ID), any()))
                .thenReturn(List.of(scheduleRow));

        var requestBody = new AttendanceController.AttendanceRequest(null, EMPLOYEE_ID, QR_TOKEN, null, null, null, null, null, null);
        AttendanceException ex = assertThrows(AttendanceException.class, () -> controller.checkIn(requestBody, employeeRequest()));

        assertEquals("INVALID_LOCATION", ex.getCode());
        assertTrue(ex.getMessage().contains("Kho hàng"));
        assertTrue(ex.getMessage().contains("Khu thu ngân"));
    }

    @Test
    void managerCanRevokeQrSession() {
        when(jdbc.update(anyString(), eq(QR_HASH))).thenReturn(1);

        var revokeRequest = new AttendanceController.RevokeQrRequest(QR_TOKEN, null);
        var response = controller.revokeQrSession(revokeRequest, managerRequest());

        assertNotNull(response);
        assertEquals(200, response.getStatusCode().value());
        assertEquals("QR đã bị thu hồi.", response.getBody().get("message"));
        assertEquals(true, response.getBody().get("revoked"));
        verify(jdbc).update(contains("UPDATE dbo.qr_sessions SET is_revoked = 1"), eq(QR_HASH));
    }
}
