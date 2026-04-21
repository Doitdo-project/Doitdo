package com.doitdo.domain.auth.api.dto.req;

import jakarta.validation.constraints.NotBlank;

public record LoginReq(

		@NotBlank
		String username,

		@NotBlank
		String password
) {
}
