package ua.kbase.kbase.config;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;

/**
 * Forwards all non-API routes to Angular's index.html (SPA support).
 */
@Controller
public class SpaController {

    @RequestMapping(value = {
            "/",
            "/{path:[^\\.]*}",
            "/{path:[^\\.]*}/**"
    })
    public String forward() {
        return "forward:/index.html";
    }
}
