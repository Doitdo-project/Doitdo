package com.doitdo.domain.notification.api.dto.resp;

import com.doitdo.domain.notification.entity.DeviceToken;
import com.doitdo.domain.notification.entity.DeviceToken.Platform;

public record DeviceTokenResp(
		Long deviceTokenId,
		String fcmToken,
		Platform platform,
		Boolean isActive
) {

	public static DeviceTokenResp from(DeviceToken deviceToken) {
		return new DeviceTokenResp(
				deviceToken.getDeviceTokenId(),
				deviceToken.getFcmToken(),
				deviceToken.getPlatform(),
				deviceToken.getIsActive()
		);
	}
}
