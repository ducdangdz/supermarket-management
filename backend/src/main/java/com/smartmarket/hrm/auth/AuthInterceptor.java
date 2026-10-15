package com.smartmarket.hrm.auth;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;
import org.springframework.web.server.ResponseStatusException;

@Component
public class AuthInterceptor implements HandlerInterceptor {
    private final GoogleTokenService tokens;
    private final AccessControl access;

    public AuthInterceptor(GoogleTokenService tokens, AccessControl access) {
        this.tokens = tokens;
        this.access = access;
    }

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
        String path = request.getRequestURI();
        if ("OPTIONS".equals(request.getMethod()) || "/api/health".equals(path) || "/api/auth/google".equals(path)) return true;

        String header = request.getHeader(HttpHeaders.AUTHORIZATION);
        if (header == null || !header.startsWith("Bearer ")) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Thiếu Authorization: Bearer <Google ID token>.");
        }
        CurrentUser user = tokens.authenticate(header.substring(7));
        request.setAttribute(AccessControl.CURRENT_USER, user);

        if (path.startsWith("/api/management/qr-sessions")) {
            access.requireManagerOrAdmin(request);
        } else if (path.startsWith("/api/management")) {
            access.requireStaff(request);
        } else if ("/api/employees".equals(path)) {
            access.requireStaff(request);
        }
        return true;
    }
}
