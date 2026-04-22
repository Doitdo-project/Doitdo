package com.doitdo.domain.notification.api.dto.req;

import com.doitdo.domain.notification.entity.DeviceToken.Platform;

public record DeviceTokenRegisterReq(
		String fcmToken,
		Platform platform
) {
}
