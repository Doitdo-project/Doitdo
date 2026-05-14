package com.doitdo.domain.auth.api.dto.req;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public record PasswordResetVerifyCodeReq(

		@NotBlank
		@Email
		String email,

		@NotBlank
		@Pattern(regexp = "\\d{6}", message = "인증번호는 6자리 숫자여야 합니다.")
		String code
) {
}
