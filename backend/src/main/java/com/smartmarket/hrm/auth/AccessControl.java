package com.smartmarket.hrm.auth;

import jakarta.servlet.http.HttpServletRequest;
import java.util.Arrays;
import java.util.Set;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ResponseStatusException;

@Component
public class AccessControl {
    public static final String CURRENT_USER = "currentUser";
    private static final Set<String> STAFF_ROLES = Set.of("ADMIN", "MANAGER", "HR");

    public CurrentUser current(HttpServletRequest request) {
        Object value = request.getAttribute(CURRENT_USER);
        if (value instanceof CurrentUser user) return user;
        throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Bạn cần đăng nhập Google.");
    }

    public void requireStaff(HttpServletRequest request) {
        if (!STAFF_ROLES.contains(current(request).roleCode())) forbidden();
    }

    public void requireManagerOrAdmin(HttpServletRequest request) {
        String role = current(request).roleCode();
        if (!"ADMIN".equals(role) && !"MANAGER".equals(role)) forbidden();
    }

    public void requireSelfOrStaff(HttpServletRequest request, Long employeeId) {
        CurrentUser user = current(request);
        if (!user.employeeId().equals(employeeId) && !STAFF_ROLES.contains(user.roleCode())) forbidden();
    }

    public void requireRole(HttpServletRequest request, String... roles) {
        if (Arrays.stream(roles).noneMatch(current(request).roleCode()::equals)) forbidden();
    }

    private void forbidden() {
        throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Bạn không có quyền thực hiện chức năng này.");
    }
}
