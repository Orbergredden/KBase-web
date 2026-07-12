package ua.kbase.kbase.controller;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;
import ua.kbase.kbase.dto.UserDto;
import ua.kbase.kbase.dto.UserSettingsUpdateDto;
import ua.kbase.kbase.entity.Role;
import ua.kbase.kbase.entity.User;
import ua.kbase.kbase.repository.RoleRepository;
import ua.kbase.kbase.repository.UserRepository;
import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class UserController {

    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final PasswordEncoder passwordEncoder;

    @GetMapping
    @PreAuthorize("hasAuthority('ADMIN_PRIVILEGE')")
    public List<UserDto> getAllUsers() {
        return userRepository.findAll().stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAuthority('ADMIN_PRIVILEGE')")
    public ResponseEntity<UserDto> getUserById(@PathVariable Long id) {
        return userRepository.findById(id)
                .map(user -> ResponseEntity.ok(convertToDto(user)))
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    @PreAuthorize("hasAuthority('ADMIN_PRIVILEGE')")
    public ResponseEntity<?> createUser(@RequestBody User userRequest, @RequestParam String roleName) {
        if (userRepository.existsByUsername(userRequest.getUsername())) {
            return ResponseEntity.badRequest().body("Ім'я користувача вже зайняте");
        }

        Role role = roleRepository.findByName(roleName)
                .orElseThrow(() -> new RuntimeException("Роль не знайдена: " + roleName));

        User user = User.builder()
                .username(userRequest.getUsername())
                .password(passwordEncoder.encode(userRequest.getPassword()))
                .email(userRequest.getEmail())
                .role(role)
                .active(userRequest.isActive())
                .build();

        User savedUser = userRepository.save(user);
        return ResponseEntity.ok(convertToDto(savedUser));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAuthority('ADMIN_PRIVILEGE')")
    public ResponseEntity<?> updateUser(@PathVariable Long id, @RequestBody User userRequest, @RequestParam(required = false) String roleName) {
        return userRepository.findById(id)
                .map(user -> {
                    user.setEmail(userRequest.getEmail());
                    user.setActive(userRequest.isActive());
                    
                    if (userRequest.getPassword() != null && !userRequest.getPassword().isEmpty()) {
                        user.setPassword(passwordEncoder.encode(userRequest.getPassword()));
                    }

                    if (roleName != null && !roleName.isEmpty()) {
                        Role role = roleRepository.findByName(roleName)
                                .orElseThrow(() -> new RuntimeException("Роль не знайдена: " + roleName));
                        user.setRole(role);
                    }

                    User updatedUser = userRepository.save(user);
                    return ResponseEntity.ok(convertToDto(updatedUser));
                })
                .orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAuthority('ADMIN_PRIVILEGE')")
    public ResponseEntity<Void> deleteUser(@PathVariable Long id) {
        if (userRepository.existsById(id)) {
            userRepository.deleteById(id);
            return ResponseEntity.ok().build();
        }
        return ResponseEntity.notFound().build();
    }

    @GetMapping("/me")
    public ResponseEntity<UserDto> getCurrentUser(java.security.Principal principal) {
        return userRepository.findByUsername(principal.getName())
                .map(user -> ResponseEntity.ok(convertToDto(user)))
                .orElse(ResponseEntity.notFound().build());
    }

    @PutMapping("/me")
    public ResponseEntity<?> updateCurrentUser(java.security.Principal principal, @RequestBody UserSettingsUpdateDto updateRequest) {
        return userRepository.findByUsername(principal.getName())
                .map(user -> {
                    user.setEmail(updateRequest.getEmail());
                    if (updateRequest.getPassword() != null && !updateRequest.getPassword().trim().isEmpty()) {
                        user.setPassword(passwordEncoder.encode(updateRequest.getPassword()));
                    }
                    User updatedUser = userRepository.save(user);
                    return ResponseEntity.ok(convertToDto(updatedUser));
                })
                .orElse(ResponseEntity.notFound().build());
    }

    private UserDto convertToDto(User user) {
        List<String> privileges = List.of();
        if (user.getRole() != null && user.getRole().getPrivileges() != null) {
            privileges = user.getRole().getPrivileges().stream()
                    .map(ua.kbase.kbase.entity.Privilege::getName)
                    .collect(Collectors.toList());
        }
        return UserDto.builder()
                .id(user.getId())
                .username(user.getUsername())
                .email(user.getEmail())
                .roleName(user.getRole() != null ? user.getRole().getName() : null)
                .privileges(privileges)
                .active(user.isActive())
                .dateCreated(user.getDateCreated())
                .dateModified(user.getDateModified())
                .build();
    }
}
