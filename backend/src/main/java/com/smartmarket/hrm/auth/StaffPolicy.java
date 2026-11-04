package com.smartmarket.hrm.auth;
import jakarta.servlet.http.HttpServletRequest;
import java.util.List;
import java.util.Map;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

/** Server-side boundaries: UI visibility alone never grants a permission. */
public final class StaffPolicy {
 private final JdbcTemplate jdbc;
 private final AccessControl access;
 public StaffPolicy(JdbcTemplate jdbc,AccessControl access){this.jdbc=jdbc;this.access=access;}
 public void branch(HttpServletRequest request,Long branchId){
   var user=access.current(request);
   access.requireStaff(request);
   if(!user.roleCode().equals("ADMIN") && (user.branchId()==null || !user.branchId().equals(branchId))) forbidden();
 }
 public void readEmployee(HttpServletRequest request,Long id){
   access.requireSelfOrStaff(request,id);
   var user=access.current(request);
   if(user.employeeId().equals(id) || user.roleCode().equals("ADMIN"))return;
   var rows=jdbc.queryForList("SELECT branch_id FROM dbo.employees WHERE employee_id=?",id);
   if(rows.isEmpty())forbidden();
   branch(request,number(rows.getFirst().get("branch_id")));
 }
 public void manageEmployee(HttpServletRequest request,Long target,Long roleId,Long branchId){
   access.requireStaff(request);
   var user=access.current(request);
   if(target!=null && target.equals(user.employeeId()))throw new ResponseStatusException(HttpStatus.FORBIDDEN,"Không thay đổi quyền hoặc khóa chính tài khoản đang đăng nhập.");
   if(user.roleCode().equals("ADMIN"))return;
   if(branchId!=null)branch(request,branchId);
   if(user.branchId()==null)forbidden();
   if(roleId!=null){
     String role=jdbc.queryForObject("SELECT role_code FROM dbo.roles WHERE role_id=?",String.class,roleId);
     if(!"EMPLOYEE".equals(role))forbidden();
   }
   if(target!=null){
     List<Map<String,Object>> rows=jdbc.queryForList("SELECT e.branch_id,r.role_code FROM dbo.employees e JOIN dbo.roles r ON r.role_id=e.role_id WHERE e.employee_id=?",target);
     if(rows.isEmpty())forbidden();
     var row=rows.getFirst();branch(request,number(row.get("branch_id")));
     if(!"EMPLOYEE".equals(row.get("role_code")))forbidden();
   }
 }
 public void shift(HttpServletRequest request,Long id){
   var rows=jdbc.queryForList("SELECT branch_id FROM dbo.shifts WHERE shift_id=?",id);
   if(rows.isEmpty())throw new IllegalArgumentException("Không tìm thấy ca làm.");
   branch(request,number(rows.getFirst().get("branch_id")));
 }
 public void schedule(HttpServletRequest request,Long id){
   var rows=jdbc.queryForList("SELECT sh.branch_id FROM dbo.work_schedules ws JOIN dbo.shifts sh ON sh.shift_id=ws.shift_id WHERE ws.schedule_id=?",id);
   if(rows.isEmpty())throw new IllegalArgumentException("Không tìm thấy lịch làm.");
   branch(request,number(rows.getFirst().get("branch_id")));
 }
 private static Long number(Object value){return value==null?null:((Number)value).longValue();}
 private static void forbidden(){throw new ResponseStatusException(HttpStatus.FORBIDDEN,"Bạn không được quản lý tài khoản hoặc dữ liệu ngoài phạm vi được cấp.");}
}
