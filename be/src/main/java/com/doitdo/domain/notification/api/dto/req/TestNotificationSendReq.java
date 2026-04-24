package com.doitdo.domain.notification.api.dto.req;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record TestNotificationSendReq(
		@NotBlank(message = "title 은 필수입니다.")
		@Size(max = 100, message = "title 은 100자 이하여야 합니다.")
		String title,

		@NotBlank(message = "message 는 필수입니다.")
		@Size(max = 500, message = "message 는 500자 이하여야 합니다.")
		String message
) {
}
