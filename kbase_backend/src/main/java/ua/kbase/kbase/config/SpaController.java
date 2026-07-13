package ua.kbase.kbase.config;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;

/**
 * Forwards Angular SPA routes to {@code index.html}.
 *
 * <p>How it works:<br>
 * Spring Boot's {@code ResourceHttpRequestHandler} is registered at {@code /**} with
 * the lowest possible precedence — controller mappings always win. That means we must
 * keep static-asset prefixes ({@code /media}, {@code /assets}, {@code /images}) out of
 * the mapping patterns entirely, so those requests bypass this controller and reach the
 * resource handler directly.
 *
 * <p>Pattern breakdown for {@code /{path:(?!media$|assets$|images$)[^\\.]*}}:
 * <ul>
 *   <li>{@code (?!media$|assets$|images$)} — negative lookahead: the path segment must
 *       NOT be exactly one of the known static-asset directory names.</li>
 *   <li>{@code [^\\.]*} — the segment must contain no dot (excludes {@code favicon.ico},
 *       hashed JS/CSS files, etc. which are served directly by the resource handler).</li>
 * </ul>
 */
@Controller
public class SpaController {

    @RequestMapping(value = {
            "/",
            "/{path:(?!media$|assets$|images$)[^\\.]*}",
            "/{path:(?!media$|assets$|images$)[^\\.]*}/**"
    })
    public String forward() {
        return "forward:/index.html";
    }
}
