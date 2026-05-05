package com.doitdo.global.client.mock;

import com.doitdo.global.client.KakaoOAuthClient;
import com.doitdo.global.client.dto.KakaoUserResp;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Primary;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

/**
 * 트랜잭션 경계 측정을 위한 Kakao OAuth 클라이언트 mock.
 *
 * <p>실제 Kakao API 호출 대신 고정된 sleep + 결정적 응답을 반환한다.
 * 측정 환경에서 외부 API 변동성을 제거해 트랜잭션 홀딩 시간 차이를 정확히 분리할 수 있게 한다.
 *
 * <p>활성화 조건 (AND):
 * <ul>
 *   <li>profile = dev 또는 local</li>
 *   <li>{@code oauth.mock.enabled=true}</li>
 * </ul>
 * prod 환경에서는 절대 활성화되지 않음.
 */
@Slf4j
@Component
@Primary
@Profile({"dev", "local"})
@ConditionalOnProperty(name = "oauth.mock.enabled", havingValue = "true")
public class MockKakaoOAuthClient extends KakaoOAuthClient {

    /** 실제 Kakao userInfo API 평균 응답시간(ms) 모사. */
    private static final long SIMULATED_API_LATENCY_MS = 300L;

    /** 결정적 응답 — 항상 동일 사용자로 인식되어 2회차+ "기존 로그인" 분기 진입. */
    private static final long MOCK_PROVIDER_ID = 999_900_001L;
    private static final String MOCK_EMAIL = "mock-kakao-001@doitdo.local";
    private static final String MOCK_NICKNAME = "mockKakao001";

    public MockKakaoOAuthClient(RestTemplate restTemplate) {
        super(restTemplate);
    }

    @Override
    public KakaoUserResp getUserInfo(String accessToken) {
        sleepUninterruptibly(SIMULATED_API_LATENCY_MS);
        return new KakaoUserResp(
                MOCK_PROVIDER_ID,
                new KakaoUserResp.KakaoAccount(true, true, true, MOCK_EMAIL,
                        new KakaoUserResp.Profile(MOCK_NICKNAME)),
                new KakaoUserResp.Properties(MOCK_NICKNAME)
        );
    }

    private void sleepUninterruptibly(long millis) {
        try {
            Thread.sleep(millis);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}
