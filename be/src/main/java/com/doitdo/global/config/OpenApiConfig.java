package com.doitdo.global.config;

import io.swagger.v3.oas.annotations.OpenAPIDefinition;
import io.swagger.v3.oas.annotations.enums.SecuritySchemeIn;
import io.swagger.v3.oas.annotations.enums.SecuritySchemeType;
import io.swagger.v3.oas.annotations.info.Contact;
import io.swagger.v3.oas.annotations.info.Info;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.security.SecurityScheme;
import org.springdoc.core.models.GroupedOpenApi;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;

@Configuration
@Profile({"dev", "local"})
@OpenAPIDefinition(
    info = @Info(
        title = "doitdo API",
        version = "0.0.1",
        description = "doitdo 백엔드 API 명세 (Swagger 자동 생성)",
        contact = @Contact(name = "doitdo backend", email = "ssafydoitdo@gmail.com")
    ),
    security = @SecurityRequirement(name = "BearerAuth")
)
@SecurityScheme(
    name = "BearerAuth",
    type = SecuritySchemeType.HTTP,
    scheme = "bearer",
    bearerFormat = "JWT",
    in = SecuritySchemeIn.HEADER
)
public class OpenApiConfig {

    @Bean
    public GroupedOpenApi auth() {
        return GroupedOpenApi.builder()
            .group("auth")
            .packagesToScan("com.doitdo.domain.auth.api.controller")
            .build();
    }

    @Bean
    public GroupedOpenApi user() {
        return GroupedOpenApi.builder()
            .group("user")
            .packagesToScan("com.doitdo.domain.user.api.controller")
            .build();
    }

    @Bean
    public GroupedOpenApi todo() {
        return GroupedOpenApi.builder()
            .group("todo")
            .packagesToScan("com.doitdo.domain.todo.api.controller")
            .build();
    }

    @Bean
    public GroupedOpenApi tamagotchi() {
        return GroupedOpenApi.builder()
            .group("tamagotchi")
            .packagesToScan("com.doitdo.domain.tamagotchi.api.controller")
            .build();
    }

    @Bean
    public GroupedOpenApi streak() {
        return GroupedOpenApi.builder()
            .group("streak")
            .packagesToScan("com.doitdo.domain.streak.api.controller")
            .build();
    }

    @Bean
    public GroupedOpenApi inventory() {
        return GroupedOpenApi.builder()
            .group("inventory")
            .packagesToScan("com.doitdo.domain.inventory.api.controller")
            .build();
    }

    @Bean
    public GroupedOpenApi shop() {
        return GroupedOpenApi.builder()
            .group("shop")
            .packagesToScan("com.doitdo.domain.shop.api.controller")
            .build();
    }

    @Bean
    public GroupedOpenApi notification() {
        return GroupedOpenApi.builder()
            .group("notification")
            .packagesToScan("com.doitdo.domain.notification.api.controller")
            .build();
    }

    @Bean
    public GroupedOpenApi setting() {
        return GroupedOpenApi.builder()
            .group("setting")
            .packagesToScan("com.doitdo.domain.setting.api.controller")
            .build();
    }

    @Bean
    public GroupedOpenApi global() {
        return GroupedOpenApi.builder()
            .group("global")
            .packagesToScan("com.doitdo.global.health")
            .build();
    }
}
