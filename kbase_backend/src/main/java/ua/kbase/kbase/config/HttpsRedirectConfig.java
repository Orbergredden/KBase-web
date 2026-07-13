package ua.kbase.kbase.config;

import org.apache.catalina.connector.Connector;
import org.springframework.boot.tomcat.TomcatWebServerFactory;
import org.springframework.boot.web.server.WebServerFactoryCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Додає другий HTTP-коннектор на порт 8080.
 * Будь-який запит на http://host:8080/... автоматично
 * перенаправляється на https://host:8443/...
 */
@Configuration
public class HttpsRedirectConfig {

    @Bean
    public WebServerFactoryCustomizer<TomcatWebServerFactory> httpToHttpsRedirect() {
        return factory -> {
            Connector http = new Connector();
            http.setPort(8080);
            http.setScheme("http");
            http.setSecure(false);
            http.setRedirectPort(8443);
            factory.addAdditionalConnectors(http);
        };
    }
}
