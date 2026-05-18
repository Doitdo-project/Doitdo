package com.doitdo.domain.setting.api.dto.req;

import java.time.LocalTime;

/**
 * 사용자 설정 부분 업데이트 요청.
 * null 필드는 기존값 유지.
 *
 * - dnd_* : 방해금지 시간대 (SET-002)
 * - morning_* : 아침 리마인드 (SET-003)
 * - evening_* : 저녁 리마인드 (SET-004)
 *
 * home_screen_mode 는 이번 스코프에서 제외.
 */
public record UserSettingUpdateReq(

		Boolean dndEnabled,

		LocalTime dndStartTime,

		LocalTime dndEndTime,

		Boolean morningReminderEnabled,

		LocalTime morningReminderTime,

		Boolean eveningReminderEnabled,

		LocalTime eveningReminderTime,

		Boolean tamagotchiNotificationEnabled
) {
}
