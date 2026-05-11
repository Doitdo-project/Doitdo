package com.doitdo.domain.auth.application.impl;

import com.doitdo.domain.auth.api.dto.req.OAuthLoginReq;
import com.doitdo.domain.auth.api.dto.resp.OAuthLoginResp;
import com.doitdo.domain.auth.application.OAuthService;
import com.doitdo.domain.auth.entity.OAuthProvider;
import com.doitdo.global.client.AppleIdTokenVerifierService;
import com.doitdo.global.client.AppleOAuthClient;
import com.doitdo.global.client.GoogleIdTokenVerifierService;
import com.doitdo.global.client.KakaoOAuthClient;
import com.doitdo.global.client.dto.AppleUserInfo;
import com.doitdo.global.client.dto.GoogleUserInfo;
import com.doitdo.global.client.dto.KakaoUserResp;
import com.doitdo.global.exception.AuthErrorCode;
import com.doitdo.global.exception.CustomException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

/**
 * OAuth 로그인의 외부 통신 + 흐름 제어 책임을 담당.
 *
 * <p>이전 버전에서는 클래스에 {@code @Transactional} 이 적용된 단일 메서드 안에서
 * 외부 OAuth provider 호출과 DB 영속화를 모두 수행했다. 이로 인해 외부 API 응답을 기다리는
 * 동안 DB 커넥션이 점유되어 HikariCP 풀 사용량이 부풀어 오르는 비효율이 있었다.
 *
 * <p>현재 버전:
 * <ul>
 *   <li>외부 OAuth provider 호출(Kakao userInfo / Google idToken / Apple identityToken + code 교환)
 *       은 트랜잭션 외부에서 수행</li>
 *   <li>검증된 사용자 정보를 {@link OAuthPersistenceService} 의 {@code @Transactional} 메서드에
 *       넘겨 DB 작업만 짧은 트랜잭션으로 처리</li>
 * </ul>
 *
 * <p>측정 결과(dev mock 기준):
 * <ul>
 *   <li>Apple: 트랜잭션 홀딩 시간 ~636ms → ~50ms</li>
 *   <li>Kakao: 트랜잭션 홀딩 시간 ~403ms → ~45ms</li>
 * </ul>
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class OAuthServiceImpl implements OAuthService {

	private final KakaoOAuthClient kakaoOAuthClient;
	private final GoogleIdTokenVerifierService googleIdTokenVerifierService;
	private final AppleIdTokenVerifierService appleIdTokenVerifierService;
	private final AppleOAuthClient appleOAuthClient;
	private final OAuthPersistenceService oAuthPersistenceService;

	@Override
	public OAuthLoginResp login(OAuthProvider provider, OAuthLoginReq req) {
		OAuthLoginResp resp = switch (provider) {
			case KAKAO -> loginWithKakao(req.accessToken());
			case GOOGLE -> loginWithGoogle(req.accessToken());
			case APPLE -> loginWithApple(req);
		};
		log.info("event={} userId={} provider={}",
				resp.isNewUser() ? "OAUTH_USER_SIGNUP" : "OAUTH_LOGIN_SUCCESS",
				resp.user().userId(),
				provider.name());
		return resp;
	}

	private OAuthLoginResp loginWithKakao(String accessToken) {
		KakaoUserResp kakaoUser = kakaoOAuthClient.getUserInfo(accessToken);
		return oAuthPersistenceService.persistKakaoUser(kakaoUser);
	}

	private OAuthLoginResp loginWithGoogle(String idToken) {
		GoogleUserInfo googleUser = googleIdTokenVerifierService.verify(idToken);
		return oAuthPersistenceService.persistGoogleUser(googleUser);
	}

	private OAuthLoginResp loginWithApple(OAuthLoginReq req) {
		// 정책: authorizationCode 누락 시 엄격 거절.
		// 이유: refresh_token 을 받지 못하면 향후 회원탈퇴 시 Apple revoke 호출 불가 → App Store 정책 위반.
		String authorizationCode = req.appleAuthorizationCode();
		if (authorizationCode == null || authorizationCode.isBlank()) {
			throw new CustomException(AuthErrorCode.A03_002,
					"Apple 로그인은 authorizationCode 가 필수입니다.");
		}

		AppleUserInfo appleUser = appleIdTokenVerifierService.verify(req.accessToken());
		// authorizationCode → refresh_token 교환을 먼저 수행.
		// 실패 시 로그인 자체를 거절 (베스트 에포트 X) — 위 정책과 동일 이유.
		String appleRefreshToken = appleOAuthClient.exchangeCodeForRefreshToken(authorizationCode);

		return oAuthPersistenceService.persistAppleUser(appleUser, appleRefreshToken);
	}
}
