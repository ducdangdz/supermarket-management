package com.smartmarket.hrm.config;

import com.smartmarket.hrm.attendance.EvidenceStorage;
import com.smartmarket.hrm.auth.AuthInterceptor;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebConfig implements WebMvcConfigurer {
    private final AuthInterceptor authInterceptor;
    private final EvidenceStorage evidenceStorage;

    public WebConfig(AuthInterceptor authInterceptor, EvidenceStorage evidenceStorage) {
        this.authInterceptor = authInterceptor;
        this.evidenceStorage = evidenceStorage;
    }

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/uploads/evidence/**").allowedOriginPatterns("http://localhost:*","http://127.0.0.1:*").allowedMethods("GET","OPTIONS").allowedHeaders("Authorization");
        registry.addMapping("/api/**")
                .allowedOriginPatterns("http://localhost:*", "http://127.0.0.1:*")
                .allowedMethods("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS")
                .allowedHeaders("*");
    }

    @Override
    public void addInterceptors(org.springframework.web.servlet.config.annotation.InterceptorRegistry registry) {
        registry.addInterceptor(authInterceptor).addPathPatterns("/api/**","/uploads/evidence/**");
    }

}
