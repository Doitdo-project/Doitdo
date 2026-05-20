package com.doitdo.domain.setting.entity;

import java.time.LocalTime;

import com.doitdo.global.entity.BaseTimeEntity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
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

	@Builder.Default
	@Column(name = "tamagotchi_notification_enabled", nullable = false)
	private Boolean tamagotchiNotificationEnabled = true;

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
				.tamagotchiNotificationEnabled(true)
				.homeScreenMode(HomeScreenMode.HOME)
				.build();
	}

	@PrePersist
	@PreUpdate
	private void normalizeTimes() {
		this.morningReminderTime = truncate(this.morningReminderTime);
		this.eveningReminderTime = truncate(this.eveningReminderTime);
		this.dndStartTime        = truncate(this.dndStartTime);
		this.dndEndTime          = truncate(this.dndEndTime);
		if (this.tamagotchiNotificationEnabled == null) {
			this.tamagotchiNotificationEnabled = true;
		}
	}

	private static LocalTime truncate(LocalTime t) {
		return t == null ? null : t.withSecond(0).withNano(0);
	}

	/**
	 * 부분 업데이트: null 인자는 기존값 유지. 방해금지/아침/저녁 3종 필드만 지원.
	 * (home_screen_mode 는 이번 스코프에서 제외)
	 */
	public void update(
			Boolean dndEnabled,
			LocalTime dndStartTime,
			LocalTime dndEndTime,
			Boolean morningReminderEnabled,
			LocalTime morningReminderTime,
			Boolean eveningReminderEnabled,
			LocalTime eveningReminderTime,
			Boolean tamagotchiNotificationEnabled
	) {
		if (dndEnabled != null) this.dndEnabled = dndEnabled;
		if (dndStartTime != null) this.dndStartTime = dndStartTime;
		if (dndEndTime != null) this.dndEndTime = dndEndTime;
		if (morningReminderEnabled != null) this.morningReminderEnabled = morningReminderEnabled;
		if (morningReminderTime != null) this.morningReminderTime = morningReminderTime;
		if (eveningReminderEnabled != null) this.eveningReminderEnabled = eveningReminderEnabled;
		if (eveningReminderTime != null) this.eveningReminderTime = eveningReminderTime;
		if (tamagotchiNotificationEnabled != null) this.tamagotchiNotificationEnabled = tamagotchiNotificationEnabled;
	}
}
