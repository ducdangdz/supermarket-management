package com.smartmarket.hrm.auth;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.web.server.ResponseStatusException;

class AccountAuthServiceTest {
    private JdbcTemplate jdbc;
    private AuthMailService mail;
    private AccountAuthService service;
    private final BCryptPasswordEncoder encoder = new BCryptPasswordEncoder(12);
    private static final String EMAIL = "employee@example.com";
    private static final String ID = UUID.randomUUID().toString();
    private static final CurrentUser USER = new CurrentUser(42L, "NV-42", "Nhân viên mới", EMAIL, "EMPLOYEE", "Nhân viên", null);

    @BeforeEach void setup() {
        jdbc = mock(JdbcTemplate.class);
        mail = mock(AuthMailService.class);
        service = new AccountAuthService(jdbc, mail);
    }
    private void loginAccount(String password) {
        when(jdbc.query(contains("WHERE (LOWER"), same(AccountAuthService.ACCOUNT), eq(EMAIL), eq(EMAIL)))
                .thenReturn(List.of(new AccountAuthService.Account(USER, encoder.encode(password))));
    }
    private void challenge(String purpose, String code) {
        when(jdbc.query(contains("WITH (UPDLOCK, HOLDLOCK)"), same(AccountAuthService.CHALLENGE), eq(ID), eq(purpose)))
                .thenReturn(List.of(new AccountAuthService.Challenge(EMAIL, encoder.encode(code), "Nhân viên mới", encoder.encode("Password123!"))));
    }
    @Test void validPasswordIssuesRandomSessionAndStoresOnlyHash() {
        loginAccount("Password123!");
        var response = service.login("  EMPLOYEE@example.com ", "Password123!");
        assertEquals(USER, response.user());
        assertTrue(response.token().startsWith("smh_"));
        assertEquals(47, response.token().length());
        verify(jdbc).update(startsWith("INSERT INTO dbo.auth_sessions"), eq(AccountAuthService.tokenHash(response.token())), eq(42L));
    }
    @Test void incorrectPasswordCannotCreateSession() {
        loginAccount("Password123!");
        var error = assertThrows(ResponseStatusException.class, () -> service.login(EMAIL, "incorrect"));
        assertEquals(HttpStatus.UNAUTHORIZED, error.getStatusCode());
        verify(jdbc, never()).update(startsWith("INSERT INTO dbo.auth_sessions"), any(), any());
    }
    @Test void repeatedWrongPasswordsAreThrottled() {
        loginAccount("Password123!");
        for (int i = 0; i < 5; i++) assertThrows(ResponseStatusException.class, () -> service.login(EMAIL, "wrong"));
        assertEquals(HttpStatus.TOO_MANY_REQUESTS,
                assertThrows(ResponseStatusException.class, () -> service.login(EMAIL, "Password123!")).getStatusCode());
    }
    @Test void registrationRequiresMailboxSetupBeforeCreatingAnything() {
        doThrow(new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE)).when(mail).ensureConfigured();
        assertThrows(ResponseStatusException.class, () -> service.register("Nhân viên", EMAIL, "Password123!"));
        verifyNoInteractions(jdbc);
    }
    @Test void registrationStoresHashedCodeAndPasswordAndDoesNotCreateEmployeeYet() {
        when(jdbc.queryForObject(startsWith("SELECT COUNT(*) FROM dbo.employees"), eq(Integer.class), eq(EMAIL))).thenReturn(0);
        var response = service.register("Nhân viên mới", EMAIL, "Password123!");
        UUID.fromString(response.challengeId());
        var code = org.mockito.ArgumentCaptor.forClass(String.class);
        verify(mail).sendCode(eq(EMAIL), code.capture(), eq("REGISTER"));
        assertTrue(code.getValue().matches("[0-9]{6}"));
        var hash = org.mockito.ArgumentCaptor.forClass(String.class);
        var passwordHash = org.mockito.ArgumentCaptor.forClass(String.class);
        verify(jdbc).update(contains("INSERT INTO dbo.auth_challenges"), eq(response.challengeId()), eq(EMAIL), eq("REGISTER"), hash.capture(), eq("Nhân viên mới"), passwordHash.capture());
        assertTrue(encoder.matches(code.getValue(), hash.getValue()));
        assertTrue(encoder.matches("Password123!", passwordHash.getValue()));
        verify(jdbc, never()).update(startsWith("INSERT INTO dbo.employees"), any(), any(), any(), any());
    }
    @Test void duplicateEmailCannotBeRegisteredAgain() {
        when(jdbc.queryForObject(startsWith("SELECT COUNT(*) FROM dbo.employees"), eq(Integer.class), eq(EMAIL))).thenReturn(1);
        assertEquals(HttpStatus.CONFLICT, assertThrows(ResponseStatusException.class,
                () -> service.register("Another", EMAIL, "Password123!")).getStatusCode());
        verify(mail, never()).sendCode(any(), any(), any());
    }
    @Test void verifiedRegistrationCreatesEmployeeRoleAndSession() {
        challenge("REGISTER", "123456");
        when(jdbc.update(startsWith("INSERT INTO dbo.employees"), anyString(), eq("Nhân viên mới"), eq(EMAIL), anyString())).thenReturn(1);
        when(jdbc.query(contains("WHERE e.email = ?"), same(AccountAuthService.ACCOUNT), eq(EMAIL)))
                .thenReturn(List.of(new AccountAuthService.Account(USER, encoder.encode("Password123!"))));
        var response = service.verifyRegistration(ID, "123456");
        assertEquals("EMPLOYEE", response.user().roleCode());
        verify(jdbc).update(contains("WHERE role_code = 'EMPLOYEE'"), startsWith("NV-"), eq("Nhân viên mới"), eq(EMAIL), anyString());
        verify(jdbc).update("UPDATE dbo.auth_challenges SET consumed = 1 WHERE challenge_id = ?", ID);
    }
    @Test void wrongCodeConsumesAttemptButNeverChangesPassword() {
        challenge("RESET", "123456");
        assertThrows(ResponseStatusException.class, () -> service.resetPassword(ID, "999999", "NewPassword123!"));
        verify(jdbc).update("UPDATE dbo.auth_challenges SET attempts = attempts + 1 WHERE challenge_id = ?", ID);
        verify(jdbc, never()).update(startsWith("UPDATE dbo.employees SET password_hash"), any(), any());
    }
    @Test void expiredOrConsumedChallengeIsRejected() {
        when(jdbc.query(contains("WITH (UPDLOCK, HOLDLOCK)"), same(AccountAuthService.CHALLENGE), eq(ID), eq("RESET"))).thenReturn(List.of());
        assertThrows(ResponseStatusException.class, () -> service.resetPassword(ID, "123456", "NewPassword123!"));
        verify(jdbc, never()).update(startsWith("UPDATE dbo.employees"), any(), any());
    }
    @Test void resetRevokesAllSessionsAndConsumesCode() {
        challenge("RESET", "123456");
        service.resetPassword(ID, "123456", "NewPassword123!");
        var hash = org.mockito.ArgumentCaptor.forClass(String.class);
        verify(jdbc).update(startsWith("UPDATE dbo.employees SET password_hash"), hash.capture(), eq(EMAIL));
        assertTrue(encoder.matches("NewPassword123!", hash.getValue()));
        verify(jdbc).update(startsWith("DELETE FROM dbo.auth_sessions WHERE employee_id IN"), eq(EMAIL));
        verify(jdbc).update("UPDATE dbo.auth_challenges SET consumed = 1 WHERE challenge_id = ?", ID);
    }
    @Test void unknownForgotAddressReturnsOpaqueIdWithoutSendingMail() {
        var response = service.forgotPassword(EMAIL);
        UUID.fromString(response.challengeId());
        verify(mail, never()).sendCode(any(), any(), any());
    }
    @Test void expiredSessionFailsAndLogoutHashesTheToken() {
        when(jdbc.query(contains("JOIN dbo.auth_sessions"), same(AccountAuthService.ACCOUNT), anyString())).thenReturn(List.of());
        assertEquals(HttpStatus.UNAUTHORIZED, assertThrows(ResponseStatusException.class, () -> service.authenticate("smh_expired")).getStatusCode());
        service.logout("smh_token");
        verify(jdbc).update("DELETE FROM dbo.auth_sessions WHERE token_hash = ?", AccountAuthService.tokenHash("smh_token"));
    }
    @Test void passwordLimitsApplyToUtf8Bytes() {
        assertThrows(ResponseStatusException.class, () -> AccountAuthService.validatePassword("short"));
        assertThrows(ResponseStatusException.class, () -> AccountAuthService.validatePassword("ắ".repeat(30)));
        assertDoesNotThrow(() -> AccountAuthService.validatePassword("ViệtNam123!"));
    }
}
