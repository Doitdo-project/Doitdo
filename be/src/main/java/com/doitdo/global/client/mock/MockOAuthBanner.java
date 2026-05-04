package com.doitdo.global.client.mock;

import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Profile;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Component;

/**
 * Mock OAuth 클라이언트가 활성화된 상태임을 부팅 시 명시적으로 경고한다.
 * 운영 환경에 잘못 활성화된 경우 로그에서 즉시 발견 가능하도록 강조 출력.
 */
@Slf4j
@Component
@Profile({"dev", "local"})
@ConditionalOnProperty(name = "oauth.mock.enabled", havingValue = "true")
public class MockOAuthBanner {

    private final Environment environment;

    public MockOAuthBanner(Environment environment) {
        this.environment = environment;
    }

    @PostConstruct
    void warn() {
        String activeProfiles = String.join(",", environment.getActiveProfiles());
        log.warn("==============================================================");
        log.warn(" OAUTH MOCK CLIENTS ARE ACTIVE — DEVELOPMENT/MEASUREMENT ONLY ");
        log.warn(" profile=[{}] oauth.mock.enabled=true", activeProfiles);
        log.warn(" Real Kakao/Google/Apple endpoints will NOT be called.       ");
        log.warn(" If you see this in production logs, STOP THE SERVER NOW.    ");
        log.warn("==============================================================");
    }
}
