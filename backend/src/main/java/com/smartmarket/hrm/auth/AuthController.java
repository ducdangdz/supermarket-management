package com.smartmarket.hrm.auth;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/auth")
public class AuthController {
    private final GoogleTokenService tokens;
    private final AccountAuthService accounts;

    public AuthController(GoogleTokenService tokens, AccountAuthService accounts) {
        this.tokens = tokens;
        this.accounts = accounts;
    }

    @PostMapping("/google")
    public AccountAuthService.LoginResponse loginWithGoogle(@Valid @RequestBody GoogleLoginRequest body) {
        return accounts.issueSession(tokens.authenticate(body.idToken()), body.deviceId());
    }

    public record GoogleLoginRequest(@NotBlank String idToken,
            @NotBlank @jakarta.validation.constraints.Pattern(regexp = "[a-f0-9]{32}") String deviceId) { }
}
