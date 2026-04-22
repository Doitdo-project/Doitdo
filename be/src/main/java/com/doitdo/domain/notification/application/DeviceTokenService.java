package com.doitdo.domain.notification.application;

import com.doitdo.domain.notification.api.dto.req.DeviceTokenRegisterReq;
import com.doitdo.domain.notification.api.dto.req.DeviceTokenUnregisterReq;
import com.doitdo.domain.notification.api.dto.resp.DeviceTokenResp;

public interface DeviceTokenService {

	DeviceTokenResp register(Long userId, DeviceTokenRegisterReq req);

	void unregister(Long userId, DeviceTokenUnregisterReq req);
}
