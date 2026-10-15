package com.smartmarket.hrm.schedule;

import com.smartmarket.hrm.auth.AccessControl;
import jakarta.servlet.http.HttpServletRequest;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/employees/{employeeId}/schedules")
public class ScheduleController {
    private final JdbcTemplate jdbcTemplate;
    private final AccessControl access;

    public ScheduleController(JdbcTemplate jdbcTemplate, AccessControl access) {
        this.jdbcTemplate = jdbcTemplate;
        this.access = access;
    }

    @GetMapping
    public List<ScheduleResponse> list(
            @PathVariable Long employeeId,
            @RequestParam(required = false) LocalDate from,
            @RequestParam(required = false) LocalDate to,
            HttpServletRequest request) {
        access.requireSelfOrStaff(request, employeeId);
        LocalDate start = from == null ? LocalDate.now().withDayOfMonth(1) : from;
        LocalDate end = to == null ? start.plusMonths(1).minusDays(1) : to;
        if (end.isBefore(start)) throw new IllegalArgumentException("Ngày kết thúc phải sau ngày bắt đầu.");

        String sql = """
                SELECT ws.schedule_id, ws.work_date, ws.schedule_status,
                       sh.shift_id, sh.shift_name, sh.start_time, sh.end_time,
                       wa.work_area_id, wa.area_name, fp.floor_name,
                       ar.attendance_id, ar.attendance_status, ar.check_in_at, ar.check_out_at
                FROM dbo.work_schedules ws
                JOIN dbo.shifts sh ON sh.shift_id = ws.shift_id
                JOIN dbo.work_areas wa ON wa.work_area_id = ws.work_area_id
                JOIN dbo.floor_plans fp ON fp.floor_plan_id = wa.floor_plan_id
                LEFT JOIN dbo.attendance_records ar ON ar.schedule_id = ws.schedule_id
                WHERE ws.employee_id = ? AND ws.work_date BETWEEN ? AND ?
                ORDER BY ws.work_date, sh.start_time
                """;
        return jdbcTemplate.query(sql, (rs, row) -> new ScheduleResponse(
                rs.getLong("schedule_id"), rs.getDate("work_date").toLocalDate(),
                rs.getString("schedule_status"), rs.getLong("shift_id"), rs.getString("shift_name"),
                rs.getTime("start_time").toLocalTime(), rs.getTime("end_time").toLocalTime(),
                rs.getLong("work_area_id"), rs.getString("area_name"), rs.getString("floor_name"),
                (Long) rs.getObject("attendance_id"), rs.getString("attendance_status"),
                rs.getTimestamp("check_in_at") == null ? null : rs.getTimestamp("check_in_at").toLocalDateTime(),
                rs.getTimestamp("check_out_at") == null ? null : rs.getTimestamp("check_out_at").toLocalDateTime()),
                employeeId, start, end);
    }

    public record ScheduleResponse(Long scheduleId, LocalDate workDate, String scheduleStatus,
            Long shiftId, String shiftName, LocalTime startTime, LocalTime endTime,
            Long workAreaId, String areaName, String floorName, Long attendanceId,
            String attendanceStatus, LocalDateTime checkInAt, LocalDateTime checkOutAt) { }
}
