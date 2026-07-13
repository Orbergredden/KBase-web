package ua.kbase.kbase.config;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.server.ResponseStatusException;

/**
 * Forwards all non-API, non-static routes to Angular's index.html (SPA support).
 * <p>
 * IMPORTANT: The regex {@code [^\\.]*} prevents matching paths whose *first* segment
 * contains a dot, but the trailing {@code /**} wildcard still matches sub-paths that
 * contain dots (e.g. {@code /media/primeicons-xxx.woff2}).
 * To guard against this, we inspect the final path segment at runtime and reject
 * requests that look like file downloads so that Spring's ResourceHttpRequestHandler
 * can serve the actual static asset from {@code resources/static/}.
 */
@Controller
public class SpaController {

    @RequestMapping(value = {
            "/",
            "/{path:[^\\.]*}",
            "/{path:[^\\.]*}/**"
    })
    public String forward(HttpServletRequest request) {
        String uri = request.getRequestURI();
        // Extract the last path segment (after the final '/')
        String lastSegment = uri.substring(uri.lastIndexOf('/') + 1);
        // If the last segment has a file extension, this is a static-asset request.
        // Throw 404 so ResourceHttpRequestHandler gets a chance to serve it,
        // or the client receives a proper "not found" instead of index.html.
        if (!lastSegment.isEmpty() && lastSegment.contains(".")) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND);
        }
        return "forward:/index.html";
    }
}
