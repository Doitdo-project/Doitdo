package com.doitdo.domain.user.api.dto.req;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record PasswordChangeReq(

		@NotBlank
		String currentPassword,

		@NotBlank
		@Size(min = 8, max = 255)
		String newPassword
) {
}
