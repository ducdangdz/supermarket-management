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
    private final AccountAuthService accounts;

    public AuthInterceptor(GoogleTokenService tokens, AccessControl access, AccountAuthService accounts) {
        this.tokens = tokens;
        this.access = access;
        this.accounts = accounts;
    }

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
        String path = request.getRequestURI();
        if ("OPTIONS".equals(request.getMethod()) || "/api/health".equals(path) || java.util.Set.of("/api/auth/google", "/api/auth/login", "/api/auth/register", "/api/auth/verify-registration", "/api/auth/forgot-password", "/api/auth/reset-password").contains(path)) return true;

        String header = request.getHeader(HttpHeaders.AUTHORIZATION);
        if (header == null || !header.startsWith("Bearer ")) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Thiếu thông tin phiên đăng nhập.");
        }
        String token = header.substring(7);
        CurrentUser user;
        try {
            user = token.startsWith("smh_") ? accounts.authenticate(token) : tokens.authenticate(token);
        } catch (org.springframework.security.oauth2.jwt.JwtException | IllegalArgumentException ex) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Phiên đăng nhập không hợp lệ.");
        }
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

