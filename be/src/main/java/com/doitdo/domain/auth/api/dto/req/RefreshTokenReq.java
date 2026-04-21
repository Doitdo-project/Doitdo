package com.doitdo.domain.auth.api.dto.req;

import jakarta.validation.constraints.NotBlank;

public record RefreshTokenReq(

		@NotBlank
		String refreshToken
) {
}
