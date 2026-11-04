package com.smartmarket.hrm.auth;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.util.Map;
import org.springframework.http.HttpHeaders;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
public class AccountAuthController {
    private final AccountAuthService accounts;
    public AccountAuthController(AccountAuthService accounts) { this.accounts = accounts; }

    @PostMapping("/login")
    public AccountAuthService.LoginResponse login(@Valid @RequestBody LoginRequest body) {
        return accounts.login(body.username(), body.password());
    }
    @PostMapping("/register")
    public AccountAuthService.ChallengeResponse register(@Valid @RequestBody RegisterRequest body) {
        return accounts.register(body.fullName(), body.email(), body.password());
    }
    @PostMapping("/verify-registration")
    public AccountAuthService.LoginResponse verifyRegistration(@Valid @RequestBody VerifyRequest body) {
        return accounts.verifyRegistration(body.challengeId(), body.code());
    }
    @PostMapping("/forgot-password")
    public AccountAuthService.ChallengeResponse forgotPassword(@Valid @RequestBody ForgotRequest body) {
        return accounts.forgotPassword(body.email());
    }
    @PostMapping("/reset-password")
    public Map<String, String> resetPassword(@Valid @RequestBody ResetRequest body) {
        accounts.resetPassword(body.challengeId(), body.code(), body.password());
        return Map.of("message", "Đã đổi mật khẩu. Vui lòng đăng nhập bằng mật khẩu mới.");
    }
    @PostMapping("/logout")
    public Map<String, String> logout(HttpServletRequest request) {
        accounts.logout(request.getHeader(HttpHeaders.AUTHORIZATION).substring(7));
        return Map.of("message", "Đã đăng xuất.");
    }
    @GetMapping("/me")
    public CurrentUser me(HttpServletRequest request) {
        return (CurrentUser) request.getAttribute(AccessControl.CURRENT_USER);
    }

    public record LoginRequest(@NotBlank @Size(max = 150) String username,
            @NotBlank @Size(max = 72) String password) { }
    public record RegisterRequest(@NotBlank @Size(max = 150) String fullName,
            @NotBlank @Email @Size(max = 150) String email,
            @NotBlank @Size(min = 8, max = 72) String password) { }
    public record ForgotRequest(@NotBlank @Email @Size(max = 150) String email) { }
    public record VerifyRequest(@NotBlank @Size(max = 36) String challengeId,
            @NotBlank @Pattern(regexp = "[0-9]{6}") String code) { }
    public record ResetRequest(@NotBlank @Size(max = 36) String challengeId,
            @NotBlank @Pattern(regexp = "[0-9]{6}") String code,
            @NotBlank @Size(min = 8, max = 72) String password) { }
}
