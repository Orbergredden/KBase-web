package ua.kbase.kbase.controller;

import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import ua.kbase.kbase.entity.Privilege;
import ua.kbase.kbase.repository.PrivilegeRepository;
import java.util.List;

@RestController
@RequestMapping("/api/privileges")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class PrivilegeController {

    private final PrivilegeRepository privilegeRepository;

    @GetMapping
    @PreAuthorize("hasAuthority('ADMIN_PRIVILEGE')")
    public List<Privilege> getAllPrivileges() {
        return privilegeRepository.findAll();
    }
}
