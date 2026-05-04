package com.doitdo.global.client.mock;

import com.doitdo.global.client.AppleOAuthClient;
import com.doitdo.global.util.AppleClientSecretGenerator;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Primary;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

/**
 * 트랜잭션 경계 측정을 위한 Apple OAuth REST 클라이언트 mock.
 *
 * <p>{@code authorizationCode → refresh_token} 교환은 Apple ID 서버 왕복이 있어
 * 실제 평균 300~500ms 가량 걸린다. mock 은 400ms sleep 으로 흉내낸다.
 *
 * <p>활성화 조건 — {@link MockKakaoOAuthClient} 참고.
 */
@Slf4j
@Component
@Primary
@Profile({"dev", "local"})
@ConditionalOnProperty(name = "oauth.mock.enabled", havingValue = "true")
public class MockAppleOAuthClient extends AppleOAuthClient {

    private static final long EXCHANGE_LATENCY_MS = 400L;
    private static final long REVOKE_LATENCY_MS = 200L;

    private static final String MOCK_REFRESH_TOKEN = "mock-apple-refresh-token-001";

    public MockAppleOAuthClient(RestTemplate restTemplate, AppleClientSecretGenerator generator) {
        super(restTemplate, generator);
    }

    @Override
    public String exchangeCodeForRefreshToken(String authorizationCode) {
        sleepUninterruptibly(EXCHANGE_LATENCY_MS);
        return MOCK_REFRESH_TOKEN;
    }

    @Override
    public void revokeRefreshToken(String refreshToken) {
        sleepUninterruptibly(REVOKE_LATENCY_MS);
    }

    private void sleepUninterruptibly(long millis) {
        try {
            Thread.sleep(millis);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}
