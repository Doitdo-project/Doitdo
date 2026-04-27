package com.doitdo.domain.auth.api.dto.req;

import jakarta.validation.constraints.NotBlank;

/**
 * 소셜 로그인 요청 바디.
 *
 * <ul>
 *   <li>{@code accessToken} — Google 의 idToken / Kakao 의 accessToken / Apple 의 identityToken(JWT). provider 별 의미는 다르지만 공통 필수.</li>
 *   <li>{@code appleAuthorizationCode} — APPLE 전용. Apple SDK 가 native 로그인에서 함께 내려주는 1회용 코드.
 *       서버는 이 코드를 Apple {@code /auth/token} 에 교환해 refresh_token 을 받아 저장하며, 회원탈퇴 시 revoke 호출에 사용한다.
 *       APPLE 가입/로그인 시 누락하면 {@code A03-002} 로 거절된다(App Store 정책상 revoke 보장 위해 엄격 검증).</li>
 * </ul>
 */
public record OAuthLoginReq(

		@NotBlank
		String accessToken,

		String appleAuthorizationCode
) {
}
