package com.doitdo.domain.setting.application;

import com.doitdo.domain.setting.api.dto.req.UserSettingUpdateReq;
import com.doitdo.domain.setting.api.dto.resp.UserSettingResp;

public interface SettingService {

	UserSettingResp getMySetting(Long userId);

	UserSettingResp updateMySetting(Long userId, UserSettingUpdateReq req);
}
