package ua.kbase.kbase.controller;

import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import ua.kbase.kbase.entity.Role;
import ua.kbase.kbase.repository.RoleRepository;
import java.util.List;

@RestController
@RequestMapping("/api/roles")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class RoleController {

    private final RoleRepository roleRepository;

    @GetMapping
    @PreAuthorize("hasAuthority('ADMIN_PRIVILEGE')")
    public List<Role> getAllRoles() {
        return roleRepository.findAll();
    }
}
