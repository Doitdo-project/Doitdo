package com.doitdo.domain.auth.api.dto.req;

import jakarta.validation.constraints.NotBlank;

public record OAuthLoginReq(

		@NotBlank
		String accessToken
) {
}
