package com.doitdo.domain.notification.entity;

import com.doitdo.global.entity.BaseTimeEntity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Getter
@Table(name = "device_tokens")
@Builder
@AllArgsConstructor(access = AccessLevel.PRIVATE)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class DeviceToken extends BaseTimeEntity {

	public enum Platform { ANDROID, IOS }

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	@Column(name = "device_token_id")
	private Long deviceTokenId;

	@Column(name = "user_id", nullable = false)
	private Long userId;

	@Column(name = "fcm_token", nullable = false, length = 255)
	private String fcmToken;

	@Enumerated(EnumType.STRING)
	@Column(nullable = false, length = 10)
	private Platform platform;

	@Column(name = "is_active", nullable = false)
	private Boolean isActive;
}
