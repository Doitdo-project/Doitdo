package com.doitdo.domain.notification.application.impl;

import com.doitdo.domain.notification.api.dto.resp.NotificationListResp;
import com.doitdo.domain.notification.api.dto.resp.NotificationReadAllResp;
import com.doitdo.domain.notification.api.dto.resp.NotificationReadResp;
import com.doitdo.domain.notification.application.NotificationService;
import com.doitdo.domain.notification.entity.Notification;
import com.doitdo.domain.notification.repository.NotificationRepository;
import com.doitdo.global.exception.CustomException;
import com.doitdo.global.exception.NotificationErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class NotificationServiceImpl implements NotificationService {

	private final NotificationRepository notificationRepository;

	@Override
	@Transactional(readOnly = true)
	public NotificationListResp list(Long userId, Boolean isRead, int page, int size) {
		PageRequest pageRequest = PageRequest.of(
				Math.max(page, 0),
				Math.max(size, 1),
				Sort.by(Sort.Order.desc("createdAt"), Sort.Order.desc("notificationId"))
		);
		Page<Notification> pageResult = isRead == null
				? notificationRepository.findAllByUserIdAndIsDeletedFalse(userId, pageRequest)
				: notificationRepository.findAllByUserIdAndIsDeletedFalseAndIsRead(userId, isRead, pageRequest);
		return NotificationListResp.from(pageResult);
	}

	@Override
	@Transactional
	public NotificationReadResp read(Long userId, Long notificationId) {
		Notification notification = notificationRepository.findByNotificationIdAndIsDeletedFalse(notificationId)
				.orElseThrow(() -> new CustomException(NotificationErrorCode.N05_003));

		if (!notification.getUserId().equals(userId)) {
			throw new CustomException(NotificationErrorCode.N05_002);
		}

		notification.markRead();
		return NotificationReadResp.from(notification);
	}

	@Override
	@Transactional
	public NotificationReadAllResp readAll(Long userId) {
		int updatedCount = notificationRepository.updateAllRead(userId, java.time.LocalDateTime.now());
		return new NotificationReadAllResp(updatedCount);
	}

	@Override
	@Transactional
	public void delete(Long userId, Long notificationId) {
		Notification notification = notificationRepository.findByNotificationIdAndIsDeletedFalse(notificationId)
				.orElseThrow(() -> new CustomException(NotificationErrorCode.N07_003));

		if (!notification.getUserId().equals(userId)) {
			throw new CustomException(NotificationErrorCode.N07_002);
		}

		notification.softDelete();
	}
}
