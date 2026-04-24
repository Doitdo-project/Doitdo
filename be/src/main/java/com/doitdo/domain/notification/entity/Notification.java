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
import java.time.LocalDateTime;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Getter
@Table(name = "notifications")
@Builder
@AllArgsConstructor(access = AccessLevel.PRIVATE)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Notification extends BaseTimeEntity {

	public enum NotificationType {
		REMINDER_EVENING,       // 저녁 미완료 TODO 리마인더 — 구현 (이번 PR)
		REMINDER_MORNING,       // TODO: 트리거 미구현 — 기획 확정 시 활성화
		TODO_UNLOCK,            // TODO: 트리거 미구현 — 기획 확정 시 활성화
		TAMAGOTCHI_FAREWELL     // TODO: 트리거 미구현 — 기획 확정 시 활성화
	}

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	@Column(name = "notification_id")
	private Long notificationId;

	@Column(name = "user_id", nullable = false)
	private Long userId;

	@Enumerated(EnumType.STRING)
	@Column(nullable = false, length = 30)
	private NotificationType type;

	@Column(nullable = false, length = 100)
	private String title;

	@Column(nullable = false, length = 500)
	private String message;

	@Column(name = "is_read", nullable = false)
	private Boolean isRead;

	@Column(name = "is_deleted", nullable = false)
	private Boolean isDeleted;

	@Column(name = "reference_id")
	private Long referenceId;

	@Column(name = "read_at")
	private LocalDateTime readAt;

	public static Notification of(
			Long userId,
			NotificationType type,
			String title,
			String message,
			Long referenceId) {
		return Notification.builder()
				.userId(userId)
				.type(type)
				.title(title)
				.message(message)
				.isRead(false)
				.isDeleted(false)
				.referenceId(referenceId)
				.readAt(null)
				.build();
	}

	public void markRead() {
		if (Boolean.TRUE.equals(this.isRead)) {
			return;
		}
		this.isRead = true;
		this.readAt = LocalDateTime.now();
	}

	public void softDelete() {
		this.isDeleted = true;
	}
}
