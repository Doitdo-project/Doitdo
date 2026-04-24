package com.doitdo.domain.notification.application.impl;

import com.doitdo.domain.notification.api.dto.resp.NotificationListResp;
import com.doitdo.domain.notification.api.dto.resp.NotificationReadAllResp;
import com.doitdo.domain.notification.api.dto.resp.NotificationReadResp;
import com.doitdo.domain.notification.api.dto.req.TestNotificationSendReq;
import com.doitdo.domain.notification.application.FcmService;
import com.doitdo.domain.notification.application.NotificationService;
import com.doitdo.domain.notification.entity.DeviceToken;
import com.doitdo.domain.notification.entity.Notification;
import com.doitdo.domain.notification.entity.Notification.NotificationType;
import com.doitdo.domain.notification.repository.DeviceTokenRepository;
import com.doitdo.domain.notification.repository.NotificationRepository;
import com.doitdo.domain.setting.entity.UserSetting;
import com.doitdo.domain.setting.repository.UserSettingRepository;
import com.doitdo.global.exception.CustomException;
import com.doitdo.global.exception.NotificationErrorCode;
import java.time.LocalTime;
import java.util.List;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Slf4j
@Service
@RequiredArgsConstructor
public class NotificationServiceImpl implements NotificationService {

	private final NotificationRepository notificationRepository;
	private final UserSettingRepository userSettingRepository;
	private final DeviceTokenRepository deviceTokenRepository;
	private final FcmService fcmService;

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

	@Override
	public void sendEveningReminder(Long userId, int pendingCount, LocalTime now) {
		String title = "저녁 미완료 TODO 알림";
		String body  = "아직 %d개의 할 일이 남아있어요.".formatted(pendingCount);

		notificationRepository.save(Notification.of(
				userId, NotificationType.REMINDER_EVENING, title, body, null));
		// ↑ save 는 자체 TX 커밋. 이후 예외가 나도 row 는 남는다.

		boolean inDnd = userSettingRepository.findByUserId(userId)
				.map(s -> isInDnd(s, now))
				.orElse(false);
		if (inDnd) {
			log.debug("[evening-reminder] dnd; fcm skipped user={}", userId);
			return;
		}

		List<DeviceToken> tokens = deviceTokenRepository.findAllByUserIdAndIsActiveTrue(userId);
		if (tokens.isEmpty()) return;

		try {
			fcmService.send(tokens, title, body);
		} catch (Exception ex) {
			log.warn("[evening-reminder] fcm failed user={}", userId, ex);
		}
	}

	@Override
	public void sendTestNotification(Long userId, TestNotificationSendReq req) {
		notificationRepository.save(Notification.of(
				userId, NotificationType.REMINDER_EVENING, req.title(), req.message(), null));

		List<DeviceToken> tokens = deviceTokenRepository.findAllByUserIdAndIsActiveTrue(userId);
		if (tokens.isEmpty()) return;

		try {
			fcmService.send(tokens, req.title(), req.message());
		} catch (Exception ex) {
			log.warn("[test-notification] fcm failed user={}", userId, ex);
		}
	}

	private boolean isInDnd(UserSetting s, LocalTime now) {
		if (!Boolean.TRUE.equals(s.getDndEnabled())) {
			return false;
		}
		LocalTime start = s.getDndStartTime();
		LocalTime end = s.getDndEndTime();
		if (start == null || end == null) {
			return false;
		}
		// 자정 교차 구간 처리 (예: 22:00~06:00)
		if (start.isBefore(end)) {
			return !now.isBefore(start) && now.isBefore(end);
		} else {
			return !now.isBefore(start) || now.isBefore(end);
		}
	}
}
