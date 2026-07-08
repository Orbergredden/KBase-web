package ua.kbase.kbase.dto;

import lombok.*;
import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserDto {
    private Long id;
    private String username;
    private String email;
    private String roleName;
    private boolean active;
    private LocalDateTime dateCreated;
    private LocalDateTime dateModified;
}
