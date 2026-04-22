package com.doitdo.domain.notification.api.dto.resp;

import com.doitdo.domain.notification.entity.Notification;
import java.time.LocalDateTime;

public record NotificationReadResp(
		Long notificationId,
		Boolean isRead,
		LocalDateTime readAt
) {

	public static NotificationReadResp from(Notification notification) {
		return new NotificationReadResp(
				notification.getNotificationId(),
				notification.getIsRead(),
				notification.getReadAt()
		);
	}
}
