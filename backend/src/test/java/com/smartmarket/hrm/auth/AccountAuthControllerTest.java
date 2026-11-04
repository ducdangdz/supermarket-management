package com.smartmarket.hrm.auth;

import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import com.smartmarket.hrm.common.ApiExceptionHandler;

class AccountAuthControllerTest {
    @Test void registrationRejectsBadEmailAndShortPasswordBeforeCallingService() throws Exception {
        var service = mock(AccountAuthService.class);
        var mvc = MockMvcBuilders.standaloneSetup(new AccountAuthController(service))
                .setControllerAdvice(new ApiExceptionHandler()).build();
        mvc.perform(post("/api/auth/register").contentType(MediaType.APPLICATION_JSON)
                .content("{\"fullName\":\"New Employee\",\"email\":\"invalid\",\"password\":\"123\"}"))
                .andExpect(status().isBadRequest());
        verifyNoInteractions(service);
    }
    @Test void clientCannotChooseAnElevatedRole() throws Exception {
        var service = mock(AccountAuthService.class);
        when(service.register("New Employee", "new@example.com", "Password123!"))
                .thenReturn(new AccountAuthService.ChallengeResponse("id", "sent"));
        var mvc = MockMvcBuilders.standaloneSetup(new AccountAuthController(service)).build();
        mvc.perform(post("/api/auth/register").contentType(MediaType.APPLICATION_JSON)
                .content("{\"fullName\":\"New Employee\",\"email\":\"new@example.com\",\"password\":\"Password123!\",\"role\":\"ADMIN\"}"))
                .andExpect(status().isOk());
        verify(service).register("New Employee", "new@example.com", "Password123!");
    }
    @Test void resetRequiresSixNumericDigits() throws Exception {
        var service = mock(AccountAuthService.class);
        var mvc = MockMvcBuilders.standaloneSetup(new AccountAuthController(service))
                .setControllerAdvice(new ApiExceptionHandler()).build();
        mvc.perform(post("/api/auth/reset-password").contentType(MediaType.APPLICATION_JSON)
                .content("{\"challengeId\":\"id\",\"code\":\"abc\",\"password\":\"Password123!\"}"))
                .andExpect(status().isBadRequest());
        verifyNoInteractions(service);
    }
}
