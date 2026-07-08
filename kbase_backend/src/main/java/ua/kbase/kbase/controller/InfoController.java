package ua.kbase.kbase.controller;

import org.springframework.boot.info.BuildProperties;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import ua.kbase.kbase.entity.Setting;
import ua.kbase.kbase.repository.SettingRepository;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/info")
@CrossOrigin(origins = "*")
public class InfoController {

    private final Optional<BuildProperties> buildProperties;
    private final SettingRepository settingRepository;

    public InfoController(Optional<BuildProperties> buildProperties, SettingRepository settingRepository) {
        this.buildProperties = buildProperties;
        this.settingRepository = settingRepository;
    }

    @GetMapping
    public Map<String, String> getInfo() {
        Map<String, String> info = new HashMap<>();

        // Backend version
        String backendVer = buildProperties
                .map(BuildProperties::getVersion)
                .orElse("0.0.1-SNAPSHOT (dev)");
        info.put("backend", backendVer);

        // Database version
        String dbVer = settingRepository.findByAlias("VERSION_DB_NUMBER")
                .map(Setting::getValue)
                .orElse("unknown");
        info.put("db", dbVer);

        // Database end date
        String dbDate = settingRepository.findByAlias("VERSION_DB_END_DATE")
                .map(Setting::getValue)
                .orElse("unknown");
        info.put("dbDate", dbDate);

        return info;
    }

    @GetMapping("/version")
    public String getVersion() {
        return buildProperties
                .map(BuildProperties::getVersion)
                .orElse("0.0.1-SNAPSHOT (dev)");
    }
}
