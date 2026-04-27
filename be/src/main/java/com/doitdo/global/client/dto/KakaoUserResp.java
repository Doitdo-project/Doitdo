package com.doitdo.global.client.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

@JsonIgnoreProperties(ignoreUnknown = true)
public record KakaoUserResp(

		Long id,

		@JsonProperty("kakao_account")
		KakaoAccount kakaoAccount,

		Properties properties
) {

	public String email() {
		return kakaoAccount != null ? kakaoAccount.email() : null;
	}

	public String nickname() {
		if (properties != null && properties.nickname() != null) {
			return properties.nickname();
		}
		if (kakaoAccount != null && kakaoAccount.profile() != null) {
			return kakaoAccount.profile().nickname();
		}
		return null;
	}

	/**
	 * Kakao 가 이메일 소유권을 검증했는지 여부.
	 * has_email / is_email_valid / is_email_verified 가 모두 true 일 때만 신뢰.
	 * 자동 계정 연결의 보안 전제.
	 */
	public boolean isEmailTrusted() {
		if (kakaoAccount == null) {
			return false;
		}
		return Boolean.TRUE.equals(kakaoAccount.hasEmail())
				&& Boolean.TRUE.equals(kakaoAccount.isEmailValid())
				&& Boolean.TRUE.equals(kakaoAccount.isEmailVerified());
	}

	@JsonIgnoreProperties(ignoreUnknown = true)
	public record KakaoAccount(
			@JsonProperty("has_email") Boolean hasEmail,
			@JsonProperty("is_email_valid") Boolean isEmailValid,
			@JsonProperty("is_email_verified") Boolean isEmailVerified,
			String email,
			Profile profile
	) {
	}

	@JsonIgnoreProperties(ignoreUnknown = true)
	public record Profile(
			String nickname
	) {
	}

	@JsonIgnoreProperties(ignoreUnknown = true)
	public record Properties(
			String nickname
	) {
	}
}
