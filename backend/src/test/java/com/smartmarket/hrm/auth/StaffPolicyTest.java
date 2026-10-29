package com.smartmarket.hrm.auth;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
import java.util.*;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.web.server.ResponseStatusException;
class StaffPolicyTest {
 private final JdbcTemplate jdbc=mock(JdbcTemplate.class);
 private final StaffPolicy policy=new StaffPolicy(jdbc,new AccessControl());
 private MockHttpServletRequest user(String role,Long branch){var r=new MockHttpServletRequest();r.setAttribute(AccessControl.CURRENT_USER,new CurrentUser(42L,"NV42","Name","e@example.com",role,role,branch));return r;}
 @Test void managerCannotGrantAdmin(){when(jdbc.queryForObject(anyString(),eq(String.class),eq(1L))).thenReturn("ADMIN");assertThrows(ResponseStatusException.class,()->policy.manageEmployee(user("MANAGER",1L),null,1L,1L));}
 @Test void managerCannotUseOtherBranch(){assertThrows(ResponseStatusException.class,()->policy.branch(user("MANAGER",1L),2L));verifyNoInteractions(jdbc);}
 @Test void unassignedManagerCannotCreateStaff(){assertThrows(ResponseStatusException.class,()->policy.manageEmployee(user("MANAGER",null),null,4L,1L));verifyNoInteractions(jdbc);}
 @Test void managerCannotModifyPrivilegedAccount(){when(jdbc.queryForList(anyString(),eq(9L))).thenReturn(List.of(Map.of("branch_id",1L,"role_code","ADMIN")));assertThrows(ResponseStatusException.class,()->policy.manageEmployee(user("MANAGER",1L),9L,null,null));}
 @Test void adminCannotLockSelf(){assertThrows(ResponseStatusException.class,()->policy.manageEmployee(user("ADMIN",1L),42L,null,null));verifyNoInteractions(jdbc);}
 @Test void employeeCanReadSelf(){policy.readEmployee(user("EMPLOYEE",null),42L);verifyNoInteractions(jdbc);}
 @Test void employeeCannotReadAnotherEmployee(){assertThrows(ResponseStatusException.class,()->policy.readEmployee(user("EMPLOYEE",1L),9L));verifyNoInteractions(jdbc);}
 @Test void adminCanManageAnotherBranch(){policy.manageEmployee(user("ADMIN",null),9L,1L,5L);verifyNoInteractions(jdbc);}
 @Test void managerCanManageEmployeeInOwnBranch(){when(jdbc.queryForObject(anyString(),eq(String.class),eq(4L))).thenReturn("EMPLOYEE");when(jdbc.queryForList(anyString(),eq(9L))).thenReturn(List.of(Map.of("branch_id",1L,"role_code","EMPLOYEE")));policy.manageEmployee(user("MANAGER",1L),9L,4L,1L);}
 @Test void managerCannotReadOtherBranchProfile(){when(jdbc.queryForList(anyString(),eq(9L))).thenReturn(List.of(Map.of("branch_id",2L)));assertThrows(ResponseStatusException.class,()->policy.readEmployee(user("MANAGER",1L),9L));}
}
