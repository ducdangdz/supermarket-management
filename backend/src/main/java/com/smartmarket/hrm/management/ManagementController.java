package com.smartmarket.hrm.management;

import com.smartmarket.hrm.auth.AccessControl;
import com.smartmarket.hrm.auth.CurrentUser;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/management")
public class ManagementController {
    private final JdbcTemplate jdbc;
    private final AccessControl access;
    private final com.smartmarket.hrm.auth.StaffPolicy policy;

    public ManagementController(JdbcTemplate jdbc, AccessControl access) {
        this.jdbc = jdbc;
        this.access = access;
        this.policy=new com.smartmarket.hrm.auth.StaffPolicy(jdbc,access);
    }

    @PostMapping("/employees")
    public ResponseEntity<Map<String, Object>> createEmployee(@Valid @RequestBody EmployeeRequest body,HttpServletRequest request) {
        policy.manageEmployee(request,null,body.roleId(),body.branchId());
        requireCount("SELECT COUNT(*) FROM dbo.roles WHERE role_id = ?", body.roleId(), "Vai trò không tồn tại.");
        requireCount("SELECT COUNT(*) FROM dbo.branches WHERE branch_id = ? AND is_active = 1", body.branchId(), "Chi nhánh không hợp lệ.");
        int count = jdbc.update("""
                INSERT INTO dbo.employees (role_id, branch_id, employee_code, full_name, email, phone, login_provider, employment_status)
                VALUES (?, ?, ?, ?, ?, ?, 'GOOGLE', 'ACTIVE')
                """, body.roleId(), body.branchId(), body.employeeCode(), body.fullName(), body.email(), body.phone());
        return ResponseEntity.status(HttpStatus.CREATED).body(Map.of("created", count == 1));
    }

    @PutMapping("/employees/{employeeId}")
    public Map<String, Object> updateEmployee(@PathVariable Long employeeId, @Valid @RequestBody EmployeeRequest body,HttpServletRequest request) {
        policy.manageEmployee(request,employeeId,body.roleId(),body.branchId());
        requireCount("SELECT COUNT(*) FROM dbo.roles WHERE role_id = ?",body.roleId(),"Vai trò không tồn tại.");
        requireCount("SELECT COUNT(*) FROM dbo.branches WHERE branch_id = ? AND is_active = 1",body.branchId(),"Chi nhánh không hợp lệ.");
        int count = jdbc.update("""
                UPDATE dbo.employees SET role_id = ?, branch_id = ?, employee_code = ?, full_name = ?, email = ?, phone = ?
                WHERE employee_id = ?
                """, body.roleId(), body.branchId(), body.employeeCode(), body.fullName(), body.email(), body.phone(), employeeId);
        if (count == 0) throw new IllegalArgumentException("Không tìm thấy nhân viên.");
        return Map.of("updated", true);
    }

    @PatchMapping("/employees/{employeeId}/status")
    public Map<String, Object> changeStatus(@PathVariable Long employeeId, @Valid @RequestBody StatusRequest body,HttpServletRequest request) {
        policy.manageEmployee(request,employeeId,null,null);
        if (!List.of("ACTIVE", "INACTIVE", "SUSPENDED").contains(body.status())) throw new IllegalArgumentException("Trạng thái không hợp lệ.");
        int count = jdbc.update("UPDATE dbo.employees SET employment_status = ? WHERE employee_id = ?", body.status(), employeeId);
        if (count == 0) throw new IllegalArgumentException("Không tìm thấy nhân viên.");
        return Map.of("updated", true, "status", body.status());
    }

    @GetMapping("/shifts")
    public List<Map<String, Object>> shifts(HttpServletRequest request) {
        Long branch=scope(request);
        return jdbc.queryForList("SELECT shift_id, branch_id, shift_code, shift_name, start_time, end_time, require_qr, require_evidence, require_location FROM dbo.shifts WHERE is_active = 1 AND (? IS NULL OR branch_id=?) ORDER BY branch_id, start_time",branch,branch);
    }

    @GetMapping("/work-areas")
    public List<Map<String, Object>> workAreas(HttpServletRequest request) {
        Long branch=scope(request);
        return jdbc.queryForList("""
                SELECT wa.work_area_id, wa.area_code, wa.area_name, wa.max_employees,
                       fp.floor_plan_id, fp.floor_name, fp.floor_number, fp.branch_id
                FROM dbo.work_areas wa
                JOIN dbo.floor_plans fp ON fp.floor_plan_id = wa.floor_plan_id
                WHERE wa.is_active = 1 AND fp.is_active = 1 AND (? IS NULL OR fp.branch_id=?)
                ORDER BY fp.branch_id, fp.floor_number, wa.area_name
                """,branch,branch);
    }

    @GetMapping("/schedules")
    public List<Map<String, Object>> schedules(
            @org.springframework.web.bind.annotation.RequestParam(required = false) LocalDate from,
            @org.springframework.web.bind.annotation.RequestParam(required = false) LocalDate to,HttpServletRequest request) {
        Long branch=scope(request);
        LocalDate start = from == null ? LocalDate.now() : from;
        LocalDate end = to == null ? start.plusDays(30) : to;
        if (end.isBefore(start)) throw new IllegalArgumentException("Ngày kết thúc phải sau ngày bắt đầu.");
        return jdbc.queryForList("""
                SELECT ws.schedule_id, ws.work_date, ws.schedule_status,
                       e.employee_code, e.full_name,
                       sh.shift_name, sh.start_time, sh.end_time,
                       wa.area_name, fp.floor_name
                FROM dbo.work_schedules ws
                JOIN dbo.employees e ON e.employee_id = ws.employee_id
                JOIN dbo.shifts sh ON sh.shift_id = ws.shift_id
                JOIN dbo.work_areas wa ON wa.work_area_id = ws.work_area_id
                JOIN dbo.floor_plans fp ON fp.floor_plan_id = wa.floor_plan_id
                WHERE ws.work_date BETWEEN ? AND ? AND (? IS NULL OR e.branch_id=?)
                ORDER BY ws.work_date, sh.start_time, e.full_name
                """, start, end,branch,branch);
    }

    @PostMapping("/shifts")
    public ResponseEntity<Map<String, Object>> createShift(@Valid @RequestBody ShiftRequest body,HttpServletRequest request) {
        policy.branch(request,body.branchId());
        if (body.startTime().equals(body.endTime())) throw new IllegalArgumentException("Giờ bắt đầu và kết thúc không được giống nhau.");
        int count = jdbc.update("""
                INSERT INTO dbo.shifts (branch_id, shift_code, shift_name, start_time, end_time, require_qr, require_evidence, require_location, allowed_late_minutes)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, body.branchId(), body.shiftCode(), body.shiftName(), body.startTime(), body.endTime(), body.requireQr(), body.requireEvidence(), body.requireLocation(), body.allowedLateMinutes() == null ? 15 : body.allowedLateMinutes());
        return ResponseEntity.status(HttpStatus.CREATED).body(Map.of("created", count == 1));
    }

    @PostMapping("/schedules")
    @Transactional
    public ResponseEntity<Map<String, Object>> createSchedule(@Valid @RequestBody ScheduleRequest body,
            HttpServletRequest request) {
        policy.readEmployee(request,body.employeeId());
        policy.shift(request,body.shiftId());
        Integer compatible = jdbc.queryForObject("""
                SELECT COUNT(*)
                FROM dbo.employees e
                JOIN dbo.shifts sh ON sh.shift_id = ? AND sh.is_active = 1
                JOIN dbo.work_areas wa ON wa.work_area_id = ? AND wa.is_active = 1
                JOIN dbo.floor_plans fp ON fp.floor_plan_id = wa.floor_plan_id AND fp.is_active = 1
                WHERE e.employee_id = ? AND e.employment_status = 'ACTIVE'
                  AND e.branch_id = sh.branch_id AND e.branch_id = fp.branch_id
                """, Integer.class, body.shiftId(), body.workAreaId(), body.employeeId());
        if (compatible == null || compatible == 0) {
            throw new IllegalArgumentException("Nhân viên, ca làm và khu vực phải đang hoạt động và thuộc cùng một chi nhánh.");
        }

        Integer overlaps = jdbc.queryForObject("""
                SELECT COUNT(*) FROM dbo.work_schedules ws
                JOIN dbo.shifts existing ON existing.shift_id = ws.shift_id
                WHERE ws.employee_id = ? AND ws.work_date = ? AND ws.schedule_status = 'SCHEDULED'
                  AND NOT (existing.end_time <= (SELECT start_time FROM dbo.shifts WHERE shift_id = ?)
                       OR existing.start_time >= (SELECT end_time FROM dbo.shifts WHERE shift_id = ?))
                """, Integer.class, body.employeeId(), body.workDate(), body.shiftId(), body.shiftId());
        if (overlaps != null && overlaps > 0) throw new IllegalArgumentException("Nhân viên đã có ca trùng thời gian trong ngày này.");

        Integer max = jdbc.queryForObject("SELECT max_employees FROM dbo.work_areas WHERE work_area_id = ?", Integer.class, body.workAreaId());
        if (max != null) {
            Integer assigned = jdbc.queryForObject("""
                    SELECT COUNT(*) FROM dbo.work_schedules
                    WHERE shift_id = ? AND work_area_id = ? AND work_date = ? AND schedule_status = 'SCHEDULED'
                    """, Integer.class, body.shiftId(), body.workAreaId(), body.workDate());
            if (assigned != null && assigned >= max) throw new IllegalArgumentException("Khu vực này đã đủ số nhân viên cho ca được chọn.");
        }
        CurrentUser current = access.current(request);
        jdbc.update("INSERT INTO dbo.work_schedules (employee_id, shift_id, work_area_id, work_date, assigned_by, note) VALUES (?, ?, ?, ?, ?, ?)",
                body.employeeId(), body.shiftId(), body.workAreaId(), body.workDate(), current.employeeId(), body.note());
        return ResponseEntity.status(HttpStatus.CREATED).body(Map.of("created", true));
    }

    @PatchMapping("/schedules/{scheduleId}/cancel")
    @Transactional
    public Map<String, Object> cancelSchedule(@PathVariable Long scheduleId,HttpServletRequest request) {
        policy.schedule(request,scheduleId);
        int count = jdbc.update("""
                UPDATE ws
                SET schedule_status = 'CANCELLED'
                FROM dbo.work_schedules ws
                WHERE ws.schedule_id = ? AND ws.schedule_status = 'SCHEDULED'
                  AND NOT EXISTS (SELECT 1 FROM dbo.attendance_records ar WHERE ar.schedule_id = ws.schedule_id)
                """, scheduleId);
        if (count == 0) {
            throw new IllegalArgumentException("Không thể hủy lịch này vì lịch không tồn tại, đã hủy hoặc đã phát sinh chấm công.");
        }
        return Map.of("cancelled", true, "scheduleId", scheduleId);
    }

    private Long scope(HttpServletRequest request) {
        access.requireStaff(request);
        var user=access.current(request);
        return user.roleCode().equals("ADMIN")?null:user.branchId()==null?-1L:user.branchId();
    }

    private void requireCount(String sql, Long id, String message) {
        Integer count = jdbc.queryForObject(sql, Integer.class, id);
        if (count == null || count == 0) throw new IllegalArgumentException(message);
    }

    public record EmployeeRequest(@NotNull Long roleId, @NotNull Long branchId, @NotBlank @jakarta.validation.constraints.Size(max=30) String employeeCode,
            @NotBlank @jakarta.validation.constraints.Size(max=150) String fullName, @Email @NotBlank @jakarta.validation.constraints.Size(max=150) String email, @jakarta.validation.constraints.Size(max=20) String phone) { }
    public record StatusRequest(@NotBlank String status) { }
    public record ShiftRequest(@NotNull Long branchId, @NotBlank String shiftCode, @NotBlank String shiftName,
            @NotNull LocalTime startTime, @NotNull LocalTime endTime, boolean requireQr,
            boolean requireEvidence, boolean requireLocation, @jakarta.validation.constraints.Min(0) @jakarta.validation.constraints.Max(1440) Integer allowedLateMinutes) { }
    public record ScheduleRequest(@NotNull Long employeeId, @NotNull Long shiftId, @NotNull Long workAreaId,
            @NotNull LocalDate workDate, @jakarta.validation.constraints.Size(max=500) String note) { }
}
