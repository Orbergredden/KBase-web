package ua.kbase.kbase.controller;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import ua.kbase.kbase.entity.Setting;
import ua.kbase.kbase.repository.SettingRepository;
import java.util.List;

@RestController
@RequestMapping("/api/settings")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class SettingController {

    private final SettingRepository settingRepository;

    @GetMapping
    public List<Setting> getAllSettings() {
        return settingRepository.findAll();
    }

    @GetMapping("/{alias}")
    public ResponseEntity<Setting> getSettingByAlias(@PathVariable String alias) {
        return settingRepository.findByAlias(alias)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public Setting createOrUpdateSetting(@RequestBody Setting setting) {
        return settingRepository.save(setting);
    }
}
