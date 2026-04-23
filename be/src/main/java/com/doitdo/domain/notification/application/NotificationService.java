package com.doitdo.domain.notification.application;

import com.doitdo.domain.notification.api.dto.resp.NotificationListResp;
import com.doitdo.domain.notification.api.dto.resp.NotificationReadAllResp;
import com.doitdo.domain.notification.api.dto.resp.NotificationReadResp;
import java.time.LocalTime;

public interface NotificationService {

	NotificationListResp list(Long userId, Boolean isRead, int page, int size);

	NotificationReadResp read(Long userId, Long notificationId);

	NotificationReadAllResp readAll(Long userId);

	void delete(Long userId, Long notificationId);

	void sendEveningReminder(Long userId, int pendingCount, LocalTime now);
}
