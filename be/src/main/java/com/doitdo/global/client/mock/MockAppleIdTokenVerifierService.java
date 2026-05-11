package com.doitdo.global.client.mock;

import com.doitdo.global.client.AppleIdTokenVerifierService;
import com.doitdo.global.client.dto.AppleUserInfo;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Primary;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

/**
 * 트랜잭션 경계 측정을 위한 Apple identityToken(JWT) 검증 mock.
 *
 * <p>실제 검증은 RS256 서명 + JWKS 조회를 동반하지만, JWKS 캐시 후에는 로컬 검증이라
 * 응답시간이 짧다. mock 은 평균 100ms 로 흉내낸다.
 *
 * <p>활성화 조건 — {@link MockKakaoOAuthClient} 참고.
 */
@Slf4j
@Component
@Primary
@Profile({"dev", "local"})
@ConditionalOnProperty(name = "oauth.mock.enabled", havingValue = "true")
public class MockAppleIdTokenVerifierService extends AppleIdTokenVerifierService {

    private static final long SIMULATED_API_LATENCY_MS = 100L;

    private static final String MOCK_SUB = "mock-apple-sub-001";
    private static final String MOCK_EMAIL = "mock-apple-001@privaterelay.appleid.com";

    public MockAppleIdTokenVerifierService(
            @Value("${apple.oauth.client-id:mock-bundle-id}") String clientId,
            RestTemplate restTemplate
    ) {
        super(clientId, restTemplate);
    }

    @Override
    public AppleUserInfo verify(String identityToken) {
        sleepUninterruptibly(SIMULATED_API_LATENCY_MS);
        return new AppleUserInfo(MOCK_SUB, MOCK_EMAIL, true);
    }

    private void sleepUninterruptibly(long millis) {
        try {
            Thread.sleep(millis);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}
