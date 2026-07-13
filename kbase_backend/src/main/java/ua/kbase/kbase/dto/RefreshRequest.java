package ua.kbase.kbase.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RefreshRequest {
    @NotBlank(message = "Refresh token є обов'язковим")
    private String refreshToken;
}
