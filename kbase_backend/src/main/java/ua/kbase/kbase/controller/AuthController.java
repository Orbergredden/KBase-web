package ua.kbase.kbase.controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import ua.kbase.kbase.dto.AuthResponse;
import ua.kbase.kbase.dto.LoginRequest;
import ua.kbase.kbase.dto.RefreshRequest;
import ua.kbase.kbase.service.AuthService;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
// CORS is handled globally by SecurityConfig — no @CrossOrigin needed here.
public class AuthController {

    private final AuthService authService;

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
        try {
            return ResponseEntity.ok(authService.login(request));
        } catch (Exception e) {
            return ResponseEntity.status(401).build();
        }
    }

    @PostMapping("/refresh")
    public ResponseEntity<AuthResponse> refresh(@Valid @RequestBody RefreshRequest request) {
        try {
            return ResponseEntity.ok(authService.refresh(request));
        } catch (Exception e) {
            return ResponseEntity.status(401).build();
        }
    }

    @PostMapping("/logout")
    public ResponseEntity<Void> logout(@RequestBody(required = false) RefreshRequest request) {
        if (request != null && request.getRefreshToken() != null) {
            authService.logout(request.getRefreshToken());
        }
        return ResponseEntity.ok().build();
    }
}
