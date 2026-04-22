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

	@JsonIgnoreProperties(ignoreUnknown = true)
	public record KakaoAccount(
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
