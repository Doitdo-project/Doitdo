package com.doitdo.domain.auth.api.dto.req;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record PasswordResetReq(

		@NotBlank
		String token,

		@NotBlank
		@Size(min = 8, max = 255)
		String newPassword
) {
}
