package ua.kbase.kbase.service;

import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ua.kbase.kbase.dto.AuthResponse;
import ua.kbase.kbase.dto.LoginRequest;
import ua.kbase.kbase.dto.RefreshRequest;
import ua.kbase.kbase.entity.RefreshToken;
import ua.kbase.kbase.entity.User;
import ua.kbase.kbase.repository.RefreshTokenRepository;
import ua.kbase.kbase.security.CustomUserDetails;
import ua.kbase.kbase.security.JwtService;
import java.time.LocalDateTime;
import java.util.Date;
import java.util.List;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final AuthenticationManager authenticationManager;
    private final RefreshTokenRepository refreshTokenRepository;
    private final JwtService jwtService;

    @Transactional
    public AuthResponse login(LoginRequest request) {
        Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.getUsername(), request.getPassword())
        );

        CustomUserDetails userDetails = (CustomUserDetails) authentication.getPrincipal();
        User user = userDetails.getUser();

        String accessToken = jwtService.generateAccessToken(userDetails);
        String refreshTokenStr = jwtService.generateRefreshToken(userDetails, request.isRememberMe());

        // Очищаємо старі токени користувача
        refreshTokenRepository.deleteByUser(user);

        // Отримуємо термін придатності
        Date expiryDate = jwtService.extractClaim(refreshTokenStr, claims -> claims.getExpiration());
        LocalDateTime expiryLocalDateTime = new java.sql.Timestamp(expiryDate.getTime()).toLocalDateTime();

        RefreshToken refreshToken = RefreshToken.builder()
                .token(refreshTokenStr)
                .user(user)
                .expiryDate(expiryLocalDateTime)
                .build();
        refreshTokenRepository.save(refreshToken);

        List<String> privileges = userDetails.getAuthorities().stream()
                .map(GrantedAuthority::getAuthority)
                .filter(auth -> !auth.startsWith("ROLE_"))
                .toList();

        String role = user.getRole() != null ? user.getRole().getName() : null;

        return AuthResponse.builder()
                .accessToken(accessToken)
                .refreshToken(refreshTokenStr)
                .username(user.getUsername())
                .role(role)
                .privileges(privileges)
                .build();
    }

    @Transactional
    public AuthResponse refresh(RefreshRequest request) {
        String refreshTokenStr = request.getRefreshToken();

        // Перевіряємо наявність в БД
        RefreshToken refreshToken = refreshTokenRepository.findByToken(refreshTokenStr)
                .orElseThrow(() -> new RuntimeException("Недійсний Refresh Token"));

        // Перевіряємо термін дії
        if (refreshToken.getExpiryDate().isBefore(LocalDateTime.now()) || jwtService.isTokenExpired(refreshTokenStr)) {
            refreshTokenRepository.delete(refreshToken);
            throw new RuntimeException("Термін дії Refresh Token закінчився");
        }

        User user = refreshToken.getUser();
        if (!user.isActive()) {
            throw new RuntimeException("Користувач заблокований");
        }

        CustomUserDetails userDetails = new CustomUserDetails(user);
        String newAccessToken = jwtService.generateAccessToken(userDetails);
        
        // Зберігаємо ту саму поведінку rememberMe
        boolean rememberMe = refreshToken.getExpiryDate().isAfter(LocalDateTime.now().plusDays(2));
        String newRefreshTokenStr = jwtService.generateRefreshToken(userDetails, rememberMe);

        // Видаляємо старий токен
        refreshTokenRepository.delete(refreshToken);

        // Зберігаємо новий токен
        Date expiryDate = jwtService.extractClaim(newRefreshTokenStr, claims -> claims.getExpiration());
        LocalDateTime expiryLocalDateTime = new java.sql.Timestamp(expiryDate.getTime()).toLocalDateTime();

        RefreshToken newRefreshToken = RefreshToken.builder()
                .token(newRefreshTokenStr)
                .user(user)
                .expiryDate(expiryLocalDateTime)
                .build();
        refreshTokenRepository.save(newRefreshToken);

        List<String> privileges = userDetails.getAuthorities().stream()
                .map(GrantedAuthority::getAuthority)
                .filter(auth -> !auth.startsWith("ROLE_"))
                .toList();

        String role = user.getRole() != null ? user.getRole().getName() : null;

        return AuthResponse.builder()
                .accessToken(newAccessToken)
                .refreshToken(newRefreshTokenStr)
                .username(user.getUsername())
                .role(role)
                .privileges(privileges)
                .build();
    }

    @Transactional
    public void logout(String refreshTokenStr) {
        if (refreshTokenStr != null) {
            refreshTokenRepository.findByToken(refreshTokenStr)
                    .ifPresent(refreshTokenRepository::delete);
        }
    }
}
