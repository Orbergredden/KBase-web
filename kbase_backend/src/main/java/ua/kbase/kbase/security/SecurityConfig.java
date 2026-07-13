package ua.kbase.kbase.security;

import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.HttpStatusEntryPoint;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import java.util.Arrays;
import java.util.Collections;

@Configuration
@EnableWebSecurity
@EnableMethodSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtAuthFilter;

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                .csrf(AbstractHttpConfigurer::disable)
                .cors(cors -> cors.configurationSource(corsConfigurationSource()))
                /*
                 * .authorizeHttpRequests(auth -> auth
                 * .requestMatchers("/api/auth/**", "/api/info/**").permitAll()
                 * .anyRequest().authenticated()
                 * )
                 */
                .authorizeHttpRequests(auth -> auth
                        // 1. Дозволяємо API авторизації та публічну інформацію
                        .requestMatchers("/api/auth/**", "/api/info/**").permitAll()

                        // 2. Дозволяємо статичні ресурси Angular (index.html, js, css, іконки,
                        // картинки)
                        .requestMatchers(
                                "/",
                                "/index.html",
                                "/favicon.ico",
                                "/*.js",
                                "/*.css",
                                "/*.png",
                                "/*.jpg",
                                "/*.svg",
                                "/*.json",
                                "/assets/**",
                                "/media/**",
                                "/images/**")
                        .permitAll()

                        // 3. Дозволяємо доступ до відомих сторінок Angular (додайте ваші URL-шляхи,
                        // якщо треба)
                        // Або просто відкриваємо GET запити до будь-яких HTML/сторінкових маршрутів
                        .requestMatchers("/login", "/register", "/articles/**", "/dashboard").permitAll()

                        // 4. Усі інші запити (наприклад, решта API) вимагають авторизації
                        .anyRequest().authenticated())
                .sessionManagement(session -> session
                        .sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .exceptionHandling(ex -> ex
                        .authenticationEntryPoint(new HttpStatusEntryPoint(HttpStatus.UNAUTHORIZED)))
                .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowedOrigins(Arrays.asList(
                "http://localhost:4200", // Angular dev (HTTP)
                "https://localhost:4200", // Angular dev (HTTPS, якщо ng serve --ssl)
                "https://localhost" // продакшн
        ));
        configuration.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        configuration.setAllowedHeaders(Arrays.asList("Authorization", "Content-Type", "Cache-Control"));
        configuration.setExposedHeaders(Collections.singletonList("Authorization"));
        configuration.setAllowCredentials(true);
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }
}
