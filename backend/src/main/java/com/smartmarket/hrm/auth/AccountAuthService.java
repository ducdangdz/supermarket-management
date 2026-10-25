package com.smartmarket.hrm.auth;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.time.Instant;
import java.util.Base64;
import java.util.HexFormat;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
public class AccountAuthService {
    private final JdbcTemplate jdbc;
    private final AuthMailService mail;
    private final BCryptPasswordEncoder passwords = new BCryptPasswordEncoder(12);
    private final SecureRandom random = new SecureRandom();
    private final Map<String, LoginFailures> failures = new ConcurrentHashMap<>();
    private static final String USER_COLUMNS = """
            SELECT e.employee_id, e.employee_code, e.full_name, e.email,
                   r.role_code, r.role_name, e.branch_id, e.password_hash
            FROM dbo.employees e JOIN dbo.roles r ON r.role_id = e.role_id
            """;
    static final RowMapper<Account> ACCOUNT = (rs, row) -> new Account(new CurrentUser(
            rs.getLong("employee_id"), rs.getString("employee_code"), rs.getString("full_name"),
            rs.getString("email"), rs.getString("role_code"), rs.getString("role_name"),
            rs.getObject("branch_id", Long.class)), rs.getString("password_hash"));
    static final RowMapper<Challenge> CHALLENGE = (rs, row) -> new Challenge(
            rs.getString("email"), rs.getString("code_hash"), rs.getString("full_name"),
            rs.getString("password_hash"));

    public AccountAuthService(JdbcTemplate jdbc, AuthMailService mail) {
        this.jdbc = jdbc;
        this.mail = mail;
    }

    public LoginResponse login(String username, String password) {
        String key = username.trim().toLowerCase(Locale.ROOT);
        LoginFailures attempts = failures.get(key);
        if (attempts != null && attempts.until().isAfter(Instant.now()) && attempts.count() >= 5) {
            throw error(HttpStatus.TOO_MANY_REQUESTS, "Đăng nhập sai nhiều lần. Vui lòng thử lại sau 15 phút.");
        }
        List<Account> accounts = jdbc.query(USER_COLUMNS + """
                WHERE (LOWER(e.email) = ? OR LOWER(e.employee_code) = ?)
                AND e.employment_status = 'ACTIVE'
                """, ACCOUNT, key, key);
        // A dummy hash avoids returning immediately for an unknown identity.
        String hash = accounts.isEmpty() || accounts.getFirst().passwordHash() == null
                ? "$2a$12$YCe8hdgS5LdQ3N76xkH4Ue3sV7uIqYL3yV02xYJnPkqQJVnBQ8gxm" : accounts.getFirst().passwordHash();
        boolean valid;
        try {
            valid = password.getBytes(StandardCharsets.UTF_8).length <= 72 && passwords.matches(password, hash);
        } catch (IllegalArgumentException ex) {
            valid = false;
        }
        if (!valid || accounts.isEmpty() || accounts.getFirst().passwordHash() == null) {
            if (failures.size() >= 10000) {
                failures.entrySet().removeIf(entry -> entry.getValue().until().isBefore(Instant.now()));
                if (failures.size() >= 10000) throw error(HttpStatus.TOO_MANY_REQUESTS, "Vui lòng thử lại sau.");
            }
            failures.compute(key, (ignored, old) -> old == null || old.until().isBefore(Instant.now())
                    ? new LoginFailures(1, Instant.now().plusSeconds(900))
                    : new LoginFailures(old.count() + 1, old.until()));
            throw error(HttpStatus.UNAUTHORIZED, "Tài khoản hoặc mật khẩu không chính xác.");
        }
        failures.remove(key);
        return issueSession(accounts.getFirst().user());
    }

    @Transactional
    public ChallengeResponse register(String name, String email, String password) {
        mail.ensureConfigured();
        validatePassword(password);
        String normalized = normalize(email);
        if (countEmail(normalized) != 0) {
            throw error(HttpStatus.CONFLICT, "Email đã có tài khoản. Hãy đăng nhập hoặc chọn Quên mật khẩu.");
        }
        return createChallenge(normalized, "REGISTER", name.trim(), passwords.encode(password));
    }

    @Transactional
    public ChallengeResponse forgotPassword(String email) {
        mail.ensureConfigured();
        String normalized = normalize(email);
        // Same response shape for known and unknown addresses; never return the code.
        if (countEmail(normalized) == 0) return new ChallengeResponse(UUID.randomUUID().toString(),
                "Nếu email hợp lệ, mã xác nhận sẽ được gửi đến hộp thư của bạn.");
        return createChallenge(normalized, "RESET", null, null);
    }

    private ChallengeResponse createChallenge(String email, String purpose, String name, String hash) {
        Integer recent = jdbc.queryForObject("""
                SELECT COUNT(*) FROM dbo.auth_challenges
                WHERE email = ? AND created_at > DATEADD(MINUTE, -15, SYSUTCDATETIME())
                """, Integer.class, email);
        if (recent != null && recent >= 3) throw error(HttpStatus.TOO_MANY_REQUESTS,
                "Bạn đã yêu cầu nhiều mã xác nhận. Vui lòng thử lại sau 15 phút.");
        String id = UUID.randomUUID().toString();
        String code = "%06d".formatted(random.nextInt(1000000));
        jdbc.update("UPDATE dbo.auth_challenges SET consumed = 1 WHERE email = ? AND purpose = ? AND consumed = 0", email, purpose);
        jdbc.update("""
                INSERT INTO dbo.auth_challenges(challenge_id, email, purpose, code_hash, full_name, password_hash, expires_at)
                VALUES (?, ?, ?, ?, ?, ?, DATEADD(MINUTE, 10, SYSUTCDATETIME()))
                """, id, email, purpose, passwords.encode(code), name, hash);
        mail.sendCode(email, code, purpose);
        return new ChallengeResponse(id, "Nếu email hợp lệ, mã xác nhận sẽ được gửi đến hộp thư của bạn.");
    }

    @Transactional(noRollbackFor = ResponseStatusException.class)
    public LoginResponse verifyRegistration(String id, String code) {
        Challenge challenge = verifyCode(id, code, "REGISTER");
        if (countEmail(challenge.email()) != 0) throw error(HttpStatus.CONFLICT,
                "Email đã có tài khoản. Hãy đăng nhập hoặc đặt lại mật khẩu.");
        String employeeCode = "NV-" + UUID.randomUUID().toString().replace("-", "").substring(0, 16).toUpperCase(Locale.ROOT);
        int inserted = jdbc.update("""
                INSERT INTO dbo.employees(role_id, employee_code, full_name, email, login_provider, password_hash, employment_status)
                SELECT role_id, ?, ?, ?, 'LOCAL', ?, 'ACTIVE' FROM dbo.roles WHERE role_code = 'EMPLOYEE'
                """, employeeCode, challenge.name(), challenge.email(), challenge.passwordHash());
        if (inserted != 1) throw new IllegalStateException("Chưa cấu hình vai trò EMPLOYEE trong cơ sở dữ liệu.");
        jdbc.update("UPDATE dbo.auth_challenges SET consumed = 1 WHERE challenge_id = ?", id);
        Account account = jdbc.query(USER_COLUMNS + " WHERE e.email = ?", ACCOUNT, challenge.email()).getFirst();
        return issueSession(account.user());
    }

    @Transactional(noRollbackFor = ResponseStatusException.class)
    public void resetPassword(String id, String code, String password) {
        validatePassword(password);
        Challenge challenge = verifyCode(id, code, "RESET");
        jdbc.update("UPDATE dbo.employees SET password_hash = ?, updated_at = SYSDATETIME() WHERE email = ?",
                passwords.encode(password), challenge.email());
        jdbc.update("DELETE FROM dbo.auth_sessions WHERE employee_id IN (SELECT employee_id FROM dbo.employees WHERE email = ?)", challenge.email());
        jdbc.update("UPDATE dbo.auth_challenges SET consumed = 1 WHERE challenge_id = ?", id);
        failures.remove(challenge.email());
    }

    private Challenge verifyCode(String id, String code, String purpose) {
        try { UUID.fromString(id); } catch (IllegalArgumentException ex) { throw invalidCode(); }
        List<Challenge> matches = jdbc.query("""
                SELECT email, code_hash, full_name, password_hash FROM dbo.auth_challenges WITH (UPDLOCK, HOLDLOCK)
                WHERE challenge_id = ? AND purpose = ? AND consumed = 0 AND attempts < 5
                AND expires_at > SYSUTCDATETIME()
                """, CHALLENGE, id, purpose);
        if (matches.isEmpty()) throw invalidCode();
        Challenge challenge = matches.getFirst();
        if (!passwords.matches(code, challenge.codeHash())) {
            jdbc.update("UPDATE dbo.auth_challenges SET attempts = attempts + 1 WHERE challenge_id = ?", id);
            throw invalidCode();
        }
        return challenge;
    }

    private LoginResponse issueSession(CurrentUser user) {
        byte[] bytes = new byte[32];
        random.nextBytes(bytes);
        String token = "smh_" + Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
        jdbc.update("DELETE FROM dbo.auth_sessions WHERE expires_at <= SYSUTCDATETIME()");
        jdbc.update("INSERT INTO dbo.auth_sessions(token_hash, employee_id, expires_at) VALUES (?, ?, DATEADD(HOUR, 8, SYSUTCDATETIME()))",
                tokenHash(token), user.employeeId());
        return new LoginResponse(token, user);
    }

    public CurrentUser authenticate(String token) {
        List<Account> accounts = jdbc.query(USER_COLUMNS + """
                JOIN dbo.auth_sessions s ON s.employee_id = e.employee_id
                WHERE s.token_hash = ? AND s.expires_at > SYSUTCDATETIME() AND e.employment_status = 'ACTIVE'
                """, ACCOUNT, tokenHash(token));
        if (accounts.isEmpty()) throw error(HttpStatus.UNAUTHORIZED, "Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.");
        return accounts.getFirst().user();
    }

    public void logout(String token) {
        if (token.startsWith("smh_")) jdbc.update("DELETE FROM dbo.auth_sessions WHERE token_hash = ?", tokenHash(token));
    }

    private int countEmail(String email) {
        Integer count = jdbc.queryForObject("SELECT COUNT(*) FROM dbo.employees WHERE LOWER(email) = ?", Integer.class, email);
        return count == null ? 0 : count;
    }
    static String normalize(String email) { return email.trim().toLowerCase(Locale.ROOT); }
    static void validatePassword(String password) {
        if (password == null || password.length() < 8 || password.getBytes(StandardCharsets.UTF_8).length > 72) {
            throw error(HttpStatus.BAD_REQUEST, "Mật khẩu cần ít nhất 8 ký tự và không quá 72 byte UTF-8.");
        }
    }
    static String tokenHash(String token) {
        try { return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(token.getBytes(StandardCharsets.UTF_8))); }
        catch (java.security.NoSuchAlgorithmException ex) { throw new IllegalStateException(ex); }
    }
    private static ResponseStatusException invalidCode() { return error(HttpStatus.BAD_REQUEST, "Mã xác nhận không đúng, hết hạn hoặc đã sử dụng."); }
    private static ResponseStatusException error(HttpStatus status, String message) { return new ResponseStatusException(status, message); }
    record Account(CurrentUser user, String passwordHash) { }
    record Challenge(String email, String codeHash, String name, String passwordHash) { }
    private record LoginFailures(int count, Instant until) { }
    public record LoginResponse(String token, CurrentUser user) { }
    public record ChallengeResponse(String challengeId, String message) { }
}
