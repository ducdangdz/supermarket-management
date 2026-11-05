package com.smartmarket.hrm.auth;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.web.server.ResponseStatusException;

class AuthInterceptorTest {
    private static final String DEVICE_ID = "0123456789abcdef0123456789abcdef";
    private final GoogleTokenService google = mock(GoogleTokenService.class);
    private final AccountAuthService accounts = mock(AccountAuthService.class);
    private final AuthInterceptor interceptor = new AuthInterceptor(google, new AccessControl(), accounts);
    private final CurrentUser employee = new CurrentUser(42L, "NV42", "Employee", "new@example.com", "EMPLOYEE", "Nhân viên", null);

    @Test void recoveryAndRegistrationArePublicWithoutOpeningOtherAuthRoutes() {
        for (String path : new String[] {"/api/auth/login", "/api/auth/register", "/api/auth/verify-registration", "/api/auth/forgot-password", "/api/auth/reset-password"}) {
            assertTrue(interceptor.preHandle(new MockHttpServletRequest("POST", path), new MockHttpServletResponse(), new Object()));
        }
        assertEquals(HttpStatus.UNAUTHORIZED, assertThrows(ResponseStatusException.class,
                () -> interceptor.preHandle(new MockHttpServletRequest("GET", "/api/auth/me"), new MockHttpServletResponse(), new Object())).getStatusCode());
        verifyNoInteractions(google, accounts);
    }
    @Test void localSessionUsesDatabaseIdentityAndDoesNotCallGoogle() {
        when(accounts.authenticate("smh_valid", DEVICE_ID)).thenReturn(employee);
        var request = new MockHttpServletRequest("GET", "/api/auth/me");
        request.addHeader("Authorization", "Bearer smh_valid");
        request.addHeader("X-Device-Id", DEVICE_ID);
        assertTrue(interceptor.preHandle(request, new MockHttpServletResponse(), new Object()));
        assertEquals(employee, request.getAttribute(AccessControl.CURRENT_USER));
        verifyNoInteractions(google);
    }
    @Test void copiedLocalTokenWithoutItsDeviceIdIsRejected() {
        when(accounts.authenticate("smh_valid", null)).thenThrow(new ResponseStatusException(HttpStatus.UNAUTHORIZED));
        var request = new MockHttpServletRequest("GET", "/api/auth/me");
        request.addHeader("Authorization", "Bearer smh_valid");
        assertEquals(HttpStatus.UNAUTHORIZED, assertThrows(ResponseStatusException.class,
                () -> interceptor.preHandle(request, new MockHttpServletResponse(), new Object())).getStatusCode());
        verify(accounts).authenticate("smh_valid", null);
        verifyNoInteractions(google);
    }
    @Test void newlyRegisteredEmployeeCannotAccessManagementApi() {
        when(accounts.authenticate("smh_valid", DEVICE_ID)).thenReturn(employee);
        var request = new MockHttpServletRequest("GET", "/api/management/shifts");
        request.addHeader("Authorization", "Bearer smh_valid");
        request.addHeader("X-Device-Id", DEVICE_ID);
        assertEquals(HttpStatus.FORBIDDEN, assertThrows(ResponseStatusException.class,
                () -> interceptor.preHandle(request, new MockHttpServletResponse(), new Object())).getStatusCode());
    }
    @Test void forgedLocalTokenCannotFallBackToGoogle() {
        when(accounts.authenticate("smh_forged", DEVICE_ID)).thenThrow(new ResponseStatusException(HttpStatus.UNAUTHORIZED));
        var request = new MockHttpServletRequest("GET", "/api/auth/me");
        request.addHeader("Authorization", "Bearer smh_forged");
        request.addHeader("X-Device-Id", DEVICE_ID);
        assertThrows(ResponseStatusException.class, () -> interceptor.preHandle(request, new MockHttpServletResponse(), new Object()));
        verifyNoInteractions(google);
    }
}
