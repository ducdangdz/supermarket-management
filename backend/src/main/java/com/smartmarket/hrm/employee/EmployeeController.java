package com.smartmarket.hrm.employee;

import com.smartmarket.hrm.auth.AccessControl;
import jakarta.servlet.http.HttpServletRequest;
import java.util.List;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/employees")
public class EmployeeController {
    private final JdbcTemplate jdbcTemplate;
    private final AccessControl access;

    public EmployeeController(JdbcTemplate jdbcTemplate, AccessControl access) {
        this.jdbcTemplate = jdbcTemplate;
        this.access = access;
    }

    @GetMapping
    public List<EmployeeResponse> findAll(@RequestParam(required = false) Long branchId) {
        String sql = """
                SELECT e.employee_id, e.employee_code, e.full_name, e.email, e.phone,
                       e.employment_status, r.role_code, r.role_name, b.branch_id, b.branch_name
                FROM dbo.employees e
                JOIN dbo.roles r ON r.role_id = e.role_id
                LEFT JOIN dbo.branches b ON b.branch_id = e.branch_id
                WHERE (? IS NULL OR e.branch_id = ?)
                ORDER BY e.full_name
                """;
        return jdbcTemplate.query(sql, mapper(), branchId, branchId);
    }

    @GetMapping("/{employeeId}")
    public EmployeeResponse findById(@PathVariable Long employeeId, HttpServletRequest request) {
        access.requireSelfOrStaff(request, employeeId);
        String sql = """
                SELECT e.employee_id, e.employee_code, e.full_name, e.email, e.phone,
                       e.employment_status, r.role_code, r.role_name, b.branch_id, b.branch_name
                FROM dbo.employees e
                JOIN dbo.roles r ON r.role_id = e.role_id
                LEFT JOIN dbo.branches b ON b.branch_id = e.branch_id
                WHERE e.employee_id = ?
                """;
        List<EmployeeResponse> employees = jdbcTemplate.query(sql, mapper(), employeeId);
        if (employees.isEmpty()) throw new IllegalArgumentException("Không tìm thấy nhân viên: " + employeeId);
        return employees.getFirst();
    }

    private RowMapper<EmployeeResponse> mapper() {
        return (rs, rowNum) -> new EmployeeResponse(
                rs.getLong("employee_id"), rs.getString("employee_code"), rs.getString("full_name"),
                rs.getString("email"), rs.getString("phone"), rs.getString("employment_status"),
                rs.getString("role_code"), rs.getString("role_name"), (Long) rs.getObject("branch_id"),
                rs.getString("branch_name"));
    }

    public record EmployeeResponse(Long employeeId, String employeeCode, String fullName, String email,
            String phone, String employmentStatus, String roleCode, String roleName, Long branchId,
            String branchName) { }
}
