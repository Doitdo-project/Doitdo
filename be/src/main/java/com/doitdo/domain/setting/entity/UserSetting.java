package com.doitdo.domain.setting.entity;

import java.time.LocalTime;

import com.doitdo.global.entity.BaseTimeEntity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Getter
@Table(name = "user_settings")
@Builder
@AllArgsConstructor(access = AccessLevel.PRIVATE)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class UserSetting extends BaseTimeEntity {

	public enum HomeScreenMode { HOME, CALENDAR }

	@Id
	@Column(name = "user_id")
	private Long userId;

	@Column(name = "dnd_enabled", nullable = false)
	private Boolean dndEnabled;

	@Column(name = "dnd_start_time")
	private LocalTime dndStartTime;

	@Column(name = "dnd_end_time")
	private LocalTime dndEndTime;

	@Column(name = "morning_reminder_enabled", nullable = false)
	private Boolean morningReminderEnabled;

	@Column(name = "morning_reminder_time", nullable = false)
	private LocalTime morningReminderTime;

	@Column(name = "evening_reminder_enabled", nullable = false)
	private Boolean eveningReminderEnabled;

	@Column(name = "evening_reminder_time", nullable = false)
	private LocalTime eveningReminderTime;

	@Enumerated(EnumType.STRING)
	@Column(name = "home_screen_mode", nullable = false, length = 10)
	private HomeScreenMode homeScreenMode;

	public static UserSetting create(Long userId) {
		return UserSetting.builder()
				.userId(userId)
				.dndEnabled(false)
				.morningReminderEnabled(false)
				.morningReminderTime(LocalTime.of(8, 0))
				.eveningReminderEnabled(false)
				.eveningReminderTime(LocalTime.of(21, 0))
				.homeScreenMode(HomeScreenMode.HOME)
				.build();
	}
}
