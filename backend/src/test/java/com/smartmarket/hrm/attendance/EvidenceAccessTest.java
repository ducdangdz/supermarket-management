package com.smartmarket.hrm.attendance;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
import java.util.*;
import com.smartmarket.hrm.auth.*;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.web.server.ResponseStatusException;
class EvidenceAccessTest {
 private final JdbcTemplate jdbc=mock(JdbcTemplate.class);
 private final EvidenceStorage storage=mock(EvidenceStorage.class);
 private final AccessControl access=new AccessControl();
 private MockHttpServletRequest user(long id,String role,Long branch){var r=new MockHttpServletRequest();r.setAttribute(AccessControl.CURRENT_USER,new CurrentUser(id,"NV","Name","e@example.com",role,role,branch));return r;}
 @Test void unsignedRequestCannotReadImage(){var c=new EvidenceController(jdbc,access,storage);assertThrows(ResponseStatusException.class,()->c.read("a".repeat(64)+".jpg",new MockHttpServletRequest()));verifyNoInteractions(jdbc,storage);}
 @Test void employeeCannotReadOtherEmployeeImage(){var c=new EvidenceController(jdbc,access,storage);when(jdbc.queryForList(anyString(),eq("a".repeat(64)))).thenReturn(List.of(Map.of("employee_id",9L)));assertThrows(ResponseStatusException.class,()->c.read("a".repeat(64)+".jpg",user(42,"EMPLOYEE",1L)));verifyNoInteractions(storage);}
 @Test void invalidFileNameCannotEscapeDirectory(){var c=new EvidenceController(jdbc,access,storage);assertThrows(ResponseStatusException.class,()->c.read("../application.yml",user(42,"ADMIN",1L)));verifyNoInteractions(jdbc,storage);}
 @Test void employeeCannotSubmitAttendanceForAnotherAccount(){var c=new AttendanceController(jdbc,access,storage);var body=new AttendanceController.AttendanceRequest(7L,9L,"qr",null,null,null,null,null,null);assertThrows(ResponseStatusException.class,()->c.checkIn(body,user(42,"EMPLOYEE",1L)));verifyNoInteractions(jdbc,storage);}
 @Test void managerCannotProxyCheckOutForAnotherAccount(){var c=new AttendanceController(jdbc,access,storage);var body=new AttendanceController.AttendanceRequest(7L,9L,"qr",null,null,null,null,null,null);assertThrows(ResponseStatusException.class,()->c.checkOut(body,user(42,"MANAGER",1L)));verifyNoInteractions(jdbc,storage);}
}
