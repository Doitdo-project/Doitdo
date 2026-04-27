package com.doitdo.domain.notification.api.dto.req;

import jakarta.validation.constraints.NotBlank;

public record DeviceTokenUnregisterReq(
		@NotBlank(message = "fcmToken 은 필수입니다.")
		String fcmToken
) {
}
