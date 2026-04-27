package com.doitdo.domain.setting.application.impl;

import com.doitdo.domain.setting.api.dto.req.UserSettingUpdateReq;
import com.doitdo.domain.setting.api.dto.resp.UserSettingResp;
import com.doitdo.domain.setting.application.SettingService;
import com.doitdo.domain.setting.entity.UserSetting;
import com.doitdo.domain.setting.repository.UserSettingRepository;
import com.doitdo.global.exception.CustomException;
import com.doitdo.global.exception.SettingErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class SettingServiceImpl implements SettingService {

	private final UserSettingRepository userSettingRepository;

	@Override
	@Transactional(readOnly = true)
	public UserSettingResp getMySetting(Long userId) {
		UserSetting setting = userSettingRepository.findByUserId(userId)
				.orElseThrow(() -> new CustomException(SettingErrorCode.C00_002));
		return UserSettingResp.from(setting);
	}

	@Override
	@Transactional
	public UserSettingResp updateMySetting(Long userId, UserSettingUpdateReq req) {
		UserSetting setting = userSettingRepository.findByUserId(userId)
				.orElseThrow(() -> new CustomException(SettingErrorCode.C00_002));

		// 검증: dndEnabled=true 이면 start/end 필수
		Boolean effectiveDndEnabled = req.dndEnabled() != null ? req.dndEnabled() : setting.getDndEnabled();
		if (Boolean.TRUE.equals(effectiveDndEnabled)) {
			java.time.LocalTime start = req.dndStartTime() != null ? req.dndStartTime() : setting.getDndStartTime();
			java.time.LocalTime end = req.dndEndTime() != null ? req.dndEndTime() : setting.getDndEndTime();
			if (start == null || end == null) {
				throw new CustomException(SettingErrorCode.C00_003,
						"방해금지 사용 시 시작/종료 시간이 모두 필요합니다.");
			}
		}

		setting.update(
				req.dndEnabled(),
				req.dndStartTime(),
				req.dndEndTime(),
				req.morningReminderEnabled(),
				req.morningReminderTime(),
				req.eveningReminderEnabled(),
				req.eveningReminderTime()
		);

		return UserSettingResp.from(setting);
	}
}
