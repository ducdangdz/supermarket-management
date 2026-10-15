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

    public AuthController(GoogleTokenService tokens) {
        this.tokens = tokens;
    }

    @PostMapping("/google")
    public CurrentUser loginWithGoogle(@Valid @RequestBody GoogleLoginRequest body) {
        return tokens.authenticate(body.idToken());
    }

    public record GoogleLoginRequest(@NotBlank String idToken) { }
}
