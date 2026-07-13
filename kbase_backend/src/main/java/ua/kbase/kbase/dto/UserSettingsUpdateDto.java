package ua.kbase.kbase.dto;

import lombok.Data;

@Data
public class UserSettingsUpdateDto {
    private String email;
    private String password;
}
