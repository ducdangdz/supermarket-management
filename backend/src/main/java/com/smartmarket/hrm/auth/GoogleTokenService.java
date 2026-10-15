package com.smartmarket.hrm.auth;

import java.util.List;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.oauth2.core.DelegatingOAuth2TokenValidator;
import org.springframework.security.oauth2.core.OAuth2Error;
import org.springframework.security.oauth2.core.OAuth2TokenValidator;
import org.springframework.security.oauth2.core.OAuth2TokenValidatorResult;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoders;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtValidators;
import org.springframework.stereotype.Service;

@Service
public class GoogleTokenService {
    private static final String GOOGLE_ISSUER = "https://accounts.google.com";
    private final JdbcTemplate jdbc;
    private final String googleClientId;
    private volatile JwtDecoder decoder;

    public GoogleTokenService(JdbcTemplate jdbc, @Value("${app.auth.google-client-id:}") String googleClientId) {
        this.jdbc = jdbc;
        this.googleClientId = googleClientId;
    }

    public CurrentUser authenticate(String idToken) {
        if (googleClientId == null || googleClientId.isBlank()) {
            throw new IllegalStateException("Chưa cấu hình GOOGLE_CLIENT_ID cho backend.");
        }
        if (idToken == null || idToken.isBlank()) throw new IllegalArgumentException("Thiếu Google ID token.");
        Jwt jwt = decoder().decode(idToken);
        Boolean verified = jwt.getClaim("email_verified");
        String email = jwt.getClaimAsString("email");
        if (!Boolean.TRUE.equals(verified) || email == null || email.isBlank()) {
            throw new IllegalArgumentException("Google account chưa xác thực email.");
        }
        List<CurrentUser> users = jdbc.query("""
                SELECT e.employee_id, e.employee_code, e.full_name, e.email,
                       r.role_code, r.role_name, e.branch_id
                FROM dbo.employees e
                JOIN dbo.roles r ON r.role_id = e.role_id
                WHERE LOWER(e.email) = LOWER(?) AND e.employment_status = 'ACTIVE'
                """, (rs, row) -> new CurrentUser(
                rs.getLong("employee_id"), rs.getString("employee_code"), rs.getString("full_name"),
                rs.getString("email"), rs.getString("role_code"), rs.getString("role_name"),
                (Long) rs.getObject("branch_id")), email);
        if (users.isEmpty()) throw new IllegalArgumentException("Tài khoản Google này chưa được cấp quyền trong hệ thống.");
        return users.getFirst();
    }

    private JwtDecoder decoder() {
        if (decoder != null) return decoder;
        synchronized (this) {
            if (decoder == null) {
                JwtDecoder configured = JwtDecoders.fromIssuerLocation(GOOGLE_ISSUER);
                OAuth2TokenValidator<Jwt> issuer = JwtValidators.createDefaultWithIssuer(GOOGLE_ISSUER);
                OAuth2TokenValidator<Jwt> audience = jwt -> jwt.getAudience().contains(googleClientId)
                        ? OAuth2TokenValidatorResult.success()
                        : OAuth2TokenValidatorResult.failure(new OAuth2Error("invalid_token", "Google token không đúng client ID.", null));
                ((org.springframework.security.oauth2.jwt.NimbusJwtDecoder) configured)
                        .setJwtValidator(new DelegatingOAuth2TokenValidator<>(issuer, audience));
                decoder = configured;
            }
            return decoder;
        }
    }
}
