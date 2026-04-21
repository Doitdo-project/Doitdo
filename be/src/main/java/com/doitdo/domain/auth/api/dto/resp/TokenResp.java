package com.doitdo.domain.auth.api.dto.resp;

public record TokenResp(

		String accessToken,
		String refreshToken
) {
}
