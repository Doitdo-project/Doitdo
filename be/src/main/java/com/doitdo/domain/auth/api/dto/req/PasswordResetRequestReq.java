package com.doitdo.domain.auth.api.dto.req;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

public record PasswordResetRequestReq(

		@NotBlank
		@Email
		String email
) {
}
