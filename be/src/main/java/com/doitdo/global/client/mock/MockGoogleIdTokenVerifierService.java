package com.doitdo.global.client.mock;

import com.doitdo.global.client.GoogleIdTokenVerifierService;
import com.doitdo.global.client.dto.GoogleUserInfo;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Primary;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

/**
 * 트랜잭션 경계 측정을 위한 Google ID Token 검증 mock.
 *
 * <p>실제 Google id_token 검증은 JWT 로컬 서명 검증(public key 캐시) 이라 외부 호출 시간이
 * 거의 없다. mock 도 이를 반영해 짧은 sleep 만 흉내낸다.
 *
 * <p>활성화 조건 — {@link MockKakaoOAuthClient} 참고.
 */
@Slf4j
@Component
@Primary
@Profile({"dev", "local"})
@ConditionalOnProperty(name = "oauth.mock.enabled", havingValue = "true")
public class MockGoogleIdTokenVerifierService extends GoogleIdTokenVerifierService {

    private static final long SIMULATED_API_LATENCY_MS = 50L;

    private static final String MOCK_SUB = "mock-google-sub-001";
    private static final String MOCK_EMAIL = "mock-google-001@doitdo.local";
    private static final String MOCK_NAME = "mockGoogle001";

    public MockGoogleIdTokenVerifierService(@Value("${google.oauth.client-id:}") String clientId) {
        super(clientId);
    }

    @Override
    public GoogleUserInfo verify(String idTokenString) {
        sleepUninterruptibly(SIMULATED_API_LATENCY_MS);
        return new GoogleUserInfo(MOCK_SUB, MOCK_EMAIL, MOCK_NAME, true);
    }

    private void sleepUninterruptibly(long millis) {
        try {
            Thread.sleep(millis);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}
