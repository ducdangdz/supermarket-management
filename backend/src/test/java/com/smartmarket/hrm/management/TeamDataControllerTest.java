package com.smartmarket.hrm.management;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
import com.smartmarket.hrm.auth.*;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.web.server.ResponseStatusException;
class TeamDataControllerTest {
 private final JdbcTemplate jdbc=mock(JdbcTemplate.class);
 private final TeamDataController controller=new TeamDataController(jdbc,new AccessControl());
 private MockHttpServletRequest request(String role) {
   var r=new MockHttpServletRequest();r.setAttribute(AccessControl.CURRENT_USER,new CurrentUser(42L,"DB42","Name","db@example.com",role,role,null));return r;
 }
 @Test void employeeCannotReadStaffDataset() {
   assertThrows(ResponseStatusException.class,()->controller.data(request("EMPLOYEE")));verifyNoInteractions(jdbc);
 }
 @Test void employeeCannotUpdateAnotherEmployeesPhone() {
   assertThrows(ResponseStatusException.class,()->controller.phone(7L,new TeamDataController.Phone("0901234567"),request("EMPLOYEE")));verifyNoInteractions(jdbc);
 }
 @Test void employeeCannotReviewAttendance() {
   assertThrows(ResponseStatusException.class,()->controller.review(1L,new TeamDataController.Review("APPROVED",null),request("EMPLOYEE")));verifyNoInteractions(jdbc);
 }
 @Test void invalidReviewDoesNotWrite() {
   assertThrows(IllegalArgumentException.class,()->controller.review(1L,new TeamDataController.Review("INVALID",null),request("MANAGER")));verifyNoInteractions(jdbc);
 }
 @Test void missingOrAlreadyReviewedRecordDoesNotChangeEvidence() {
   assertThrows(IllegalArgumentException.class,()->controller.review(1L,new TeamDataController.Review("APPROVED",null),request("MANAGER")));
   verify(jdbc,never()).update(startsWith("UPDATE dbo.attendance_evidence"),any(),any(),any());
 }
}
