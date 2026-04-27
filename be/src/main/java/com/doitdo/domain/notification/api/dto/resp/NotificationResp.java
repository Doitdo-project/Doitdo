package com.doitdo.domain.notification.api.dto.resp;

import com.doitdo.domain.notification.entity.Notification;
import com.doitdo.domain.notification.entity.Notification.NotificationType;
import java.time.LocalDateTime;

public record NotificationResp(
		Long notificationId,
		NotificationType type,
		String title,
		String message,
		Boolean isRead,
		Long referenceId,
		LocalDateTime readAt,
		LocalDateTime createdAt
) {

	public static NotificationResp from(Notification notification) {
		return new NotificationResp(
				notification.getNotificationId(),
				notification.getType(),
				notification.getTitle(),
				notification.getMessage(),
				notification.getIsRead(),
				notification.getReferenceId(),
				notification.getReadAt(),
				notification.getCreatedAt()
		);
	}
}
