package com.smartmarket.hrm.management;

import com.smartmarket.hrm.auth.AccessControl;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import java.util.Map;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

/** Database adapters for the original team UI. Authentication stays in AuthInterceptor. */
@RestController
public class TeamDataController {
    private final JdbcTemplate jdbc;
    private final AccessControl access;
    private final com.smartmarket.hrm.auth.StaffPolicy policy;
    public TeamDataController(JdbcTemplate jdbc, AccessControl access) { this.jdbc=jdbc; this.access=access;this.policy=new com.smartmarket.hrm.auth.StaffPolicy(jdbc,access); }

    @GetMapping("/api/management/team-data")
    public Map<String,Object> data(HttpServletRequest request) {
        access.requireStaff(request);
        return Map.of(
          "roles", rows(request,"roles","SELECT role_id,role_code,role_name FROM dbo.roles"),
          "branches", rows(request,"branches","SELECT branch_id,branch_code,branch_name,address,phone,latitude,longitude,is_active FROM dbo.branches ORDER BY branch_id"),
          "employees", rows(request,"employees","SELECT employee_id,role_id,branch_id,employee_code,full_name,email,phone,avatar_url,employment_status,hired_date FROM dbo.employees"),
          "floors", rows(request,"floors","SELECT floor_plan_id,branch_id,floor_number,floor_name,image_url,image_width,image_height,is_active FROM dbo.floor_plans"),
          "areas", rows(request,"areas","SELECT work_area_id,floor_plan_id,area_code,area_name,area_type,max_employees,map_x,map_y,map_width,map_height,latitude,longitude,radius_meters,is_active FROM dbo.work_areas"),
          "shifts", rows(request,"shifts","SELECT shift_id,branch_id,shift_code,shift_name,start_time,end_time,check_in_early_minutes,allowed_late_minutes,allowed_early_checkout_minutes,require_qr,require_evidence,require_location,is_active FROM dbo.shifts"),
          "schedules", rows(request,"schedules","SELECT schedule_id,employee_id,shift_id,work_area_id,work_date,schedule_status,assigned_by,note FROM dbo.work_schedules"),
          "attendance", rows(request,"attendance","""
              SELECT ar.attendance_id,ar.schedule_id,ar.employee_id,ar.check_in_at,ar.check_out_at,
                     ar.check_in_latitude,ar.check_in_longitude,ar.check_out_latitude,ar.check_out_longitude,
                     CASE WHEN ar.check_in_at > timing.starts_at
                          THEN DATEDIFF(MINUTE,timing.starts_at,ar.check_in_at) ELSE 0 END AS late_minutes,
                     ar.attendance_status,ar.verification_status,ar.verified_by,ar.verified_at,ar.note
              FROM dbo.attendance_records ar
              JOIN dbo.work_schedules ws ON ws.schedule_id=ar.schedule_id
              JOIN dbo.shifts sh ON sh.shift_id=ws.shift_id
              CROSS APPLY (SELECT DATEADD(SECOND,DATEDIFF(SECOND,CAST('00:00:00' AS TIME),sh.start_time),
                                          CAST(ws.work_date AS DATETIME2)) AS starts_at) timing
              """),
          "evidence", rows(request,"evidence","SELECT evidence_id,attendance_id,evidence_type,file_url,file_hash,captured_at,latitude,longitude,review_status,reviewed_by,reviewed_at FROM dbo.attendance_evidence"));
    }

    private java.util.List<java.util.Map<String,Object>> rows(HttpServletRequest request,String kind,String sql) {
        var user=access.current(request);
        if(user.roleCode().equals("ADMIN") || kind.equals("roles"))return jdbc.queryForList(sql);
        Long branch=user.branchId()==null?-1L:user.branchId();
        String predicate=switch(kind){
            case "branches","employees","shifts" -> "branch_id=?";
            case "floors" -> "branch_id=?";
            case "areas" -> "floor_plan_id IN (SELECT floor_plan_id FROM dbo.floor_plans WHERE branch_id=?)";
            case "schedules" -> "employee_id IN (SELECT employee_id FROM dbo.employees WHERE branch_id=?)";
            case "attendance" -> "ar.employee_id IN (SELECT employee_id FROM dbo.employees WHERE branch_id=?)";
            case "evidence" -> "attendance_id IN (SELECT attendance_id FROM dbo.attendance_records WHERE employee_id IN (SELECT employee_id FROM dbo.employees WHERE branch_id=?))";
            default -> throw new IllegalArgumentException("Nguồn dữ liệu không hợp lệ.");
        };
        sql=sql.replace(" ORDER BY branch_id","").stripTrailing();
        return jdbc.queryForList(sql+" WHERE "+predicate,branch);
    }

    @PatchMapping("/api/employees/{id}/phone")
    public Map<String,Object> phone(@PathVariable Long id, @Valid @RequestBody Phone body, HttpServletRequest request) {
        policy.readEmployee(request,id);
        if(jdbc.update("UPDATE dbo.employees SET phone=?,updated_at=SYSDATETIME() WHERE employee_id=?",body.phone(),id)!=1)
            throw new IllegalArgumentException("Không tìm thấy nhân viên.");
        return Map.of("updated",true);
    }
    public record Phone(@NotBlank @Pattern(regexp="[+0-9 ()-]{5,20}") String phone) {}

    @PatchMapping("/api/management/team-shifts/{id}/status")
    public Map<String,Object> shiftStatus(@PathVariable Long id,@RequestBody ShiftStatus body,HttpServletRequest request) {
        access.requireStaff(request);
        policy.shift(request,id);
        if(jdbc.update("UPDATE dbo.shifts SET is_active=? WHERE shift_id=?",body.active(),id)!=1)
            throw new IllegalArgumentException("Không tìm thấy ca làm.");
        return Map.of("updated",true);
    }
    public record ShiftStatus(boolean active) {}

    @PostMapping("/api/management/team-attendance/{id}/review")
    @Transactional
    public Map<String,Object> review(@PathVariable Long id,@Valid @RequestBody Review body,HttpServletRequest request) {
        access.requireStaff(request);
        if(!body.decision().equals("APPROVED") && !body.decision().equals("REJECTED"))
            throw new IllegalArgumentException("Quyết định không hợp lệ.");
        var current=access.current(request);
        if(!current.roleCode().equals("ADMIN")) {
            var targets=jdbc.queryForList("SELECT e.branch_id FROM dbo.attendance_records ar JOIN dbo.employees e ON e.employee_id=ar.employee_id WHERE ar.attendance_id=?",id);
            if(targets.isEmpty())throw new IllegalArgumentException("Không tìm thấy bản ghi chấm công.");
            Object branch=targets.getFirst().get("branch_id");
            policy.branch(request,branch==null?null:((Number)branch).longValue());
        }
        boolean approved=body.decision().equals("APPROVED");
        Long reviewer=access.current(request).employeeId();
        int count=jdbc.update("""
            UPDATE ar SET verification_status=?,
              attendance_status=CASE WHEN ?=1 THEN
                CASE WHEN ar.check_in_at > DATEADD(MINUTE,sh.allowed_late_minutes,timing.starts_at)
                     THEN 'LATE' ELSE 'PRESENT' END ELSE 'REJECTED' END,
              verified_by=?,verified_at=SYSDATETIME(),note=?
            FROM dbo.attendance_records ar
            JOIN dbo.work_schedules ws ON ws.schedule_id=ar.schedule_id
            JOIN dbo.shifts sh ON sh.shift_id=ws.shift_id
            CROSS APPLY (SELECT DATEADD(SECOND,DATEDIFF(SECOND,CAST('00:00:00' AS TIME),sh.start_time),
                                        CAST(ws.work_date AS DATETIME2)) AS starts_at) timing
            WHERE ar.attendance_id=? AND ar.verification_status='PENDING'
            """, approved?"VERIFIED":"REJECTED",approved,reviewer,body.note(),id);
        if(count!=1) throw new IllegalArgumentException("Bản ghi không tồn tại hoặc đã được duyệt. Hãy tải lại dữ liệu.");
        jdbc.update("UPDATE dbo.attendance_evidence SET review_status=?,reviewed_by=?,reviewed_at=SYSDATETIME() WHERE attendance_id=?",body.decision(),reviewer,id);
        return Map.of("updated",true);
    }
    public record Review(@NotBlank String decision,String note) {}
}
