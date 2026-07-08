package ua.kbase.kbase.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LoginRequest {
    @NotBlank(message = "Ім'я користувача не може бути порожнім")
    private String username;

    @NotBlank(message = "Пароль не може бути порожнім")
    private String password;

    private boolean rememberMe;
}
