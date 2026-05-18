package com.doitdo.domain.setting.api.dto.resp;

import com.doitdo.domain.setting.entity.UserSetting;
import java.time.LocalTime;

public record UserSettingResp(

		Boolean dndEnabled,
		LocalTime dndStartTime,
		LocalTime dndEndTime,
		Boolean morningReminderEnabled,
		LocalTime morningReminderTime,
		Boolean eveningReminderEnabled,
		LocalTime eveningReminderTime,
		Boolean tamagotchiNotificationEnabled
) {

	public static UserSettingResp from(UserSetting setting) {
		return new UserSettingResp(
				setting.getDndEnabled(),
				setting.getDndStartTime(),
				setting.getDndEndTime(),
				setting.getMorningReminderEnabled(),
				setting.getMorningReminderTime(),
				setting.getEveningReminderEnabled(),
				setting.getEveningReminderTime(),
				setting.getTamagotchiNotificationEnabled()
		);
	}
}
