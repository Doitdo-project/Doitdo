package com.doitdo.domain.notification.application.impl;

import com.doitdo.domain.notification.api.dto.req.DeviceTokenRegisterReq;
import com.doitdo.domain.notification.api.dto.req.DeviceTokenUnregisterReq;
import com.doitdo.domain.notification.api.dto.resp.DeviceTokenResp;
import com.doitdo.domain.notification.application.DeviceTokenService;
import com.doitdo.domain.notification.entity.DeviceToken;
import com.doitdo.domain.notification.repository.DeviceTokenRepository;
import com.doitdo.global.exception.CustomException;
import com.doitdo.global.exception.NotificationErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

@Service
@RequiredArgsConstructor
public class DeviceTokenServiceImpl implements DeviceTokenService {

	private final DeviceTokenRepository deviceTokenRepository;

	@Override
	@Transactional
	public DeviceTokenResp register(Long userId, DeviceTokenRegisterReq req) {
		if (!StringUtils.hasText(req.fcmToken()) || req.platform() == null) {
			throw new CustomException(NotificationErrorCode.N03_002);
		}

		DeviceToken deviceToken = deviceTokenRepository.findByFcmToken(req.fcmToken())
				.map(existing -> {
					existing.register(userId, req.platform());
					return existing;
				})
				.orElseGet(() -> DeviceToken.create(userId, req.fcmToken(), req.platform()));

		return DeviceTokenResp.from(deviceTokenRepository.save(deviceToken));
	}

	@Override
	@Transactional
	public void unregister(Long userId, DeviceTokenUnregisterReq req) {
		DeviceToken deviceToken = deviceTokenRepository.findByUserIdAndFcmTokenAndIsActiveTrue(userId, req.fcmToken())
				.orElseThrow(() -> new CustomException(NotificationErrorCode.N02_002));

		deviceToken.deactivate();
	}
}
