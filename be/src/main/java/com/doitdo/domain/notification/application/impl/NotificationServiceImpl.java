package com.doitdo.domain.notification.application.impl;

import com.doitdo.domain.notification.api.dto.resp.NotificationListResp;
import com.doitdo.domain.notification.api.dto.resp.NotificationReadAllResp;
import com.doitdo.domain.notification.api.dto.resp.NotificationReadResp;
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
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.ZoneId;
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

		dispatchFcm(userId, now, title, body, "[evening-reminder]");
	}

	@Override
	public void sendTodoDone(Long userId, Long todoId, String todoTitle) {
		String title = "할 일 완료!";
		String body  = "\"%s\" 완료를 기록했어요. 잘 했어요!".formatted(todoTitle);

		notificationRepository.save(Notification.of(
				userId, NotificationType.TODO_DONE, title, body, todoId));

		LocalTime now = LocalTime.now(ZoneId.of("Asia/Seoul"));
		dispatchFcm(userId, now, title, body, "[todo-done]");
	}

	@Override
	public void sendTodoAlert(Long userId, Long todoId, String todoTitle) {
		String title = "할 일 알림";
		String body  = "\"%s\" 시작할 시간이에요.".formatted(todoTitle);

		notificationRepository.save(Notification.of(
				userId, NotificationType.TODO_REMINDER, title, body, todoId));

		LocalTime now = LocalTime.now(ZoneId.of("Asia/Seoul"));
		dispatchFcm(userId, now, title, body, "[todo-alert]");
	}

	@Override
	public void sendTodoSnoozed(Long userId, Long todoId, String todoTitle, LocalDate toDate) {
		String title = "할 일을 미뤘어요";
		String body  = "\"%s\"을(를) %s(으)로 미뤘어요.".formatted(todoTitle, toDate);

		notificationRepository.save(Notification.of(
				userId, NotificationType.TODO_SNOOZED, title, body, todoId));

		LocalTime now = LocalTime.now(ZoneId.of("Asia/Seoul"));
		dispatchFcm(userId, now, title, body, "[todo-snoozed]");
	}

	@Override
	public void sendTamagotchiFarewell(Long userId, Long userCharacterId, String beforeCharacterName) {
		String title = "다마고치와 작별했어요";
		String body  = "\"%s\"의 독립을 응원해요. 새 친구가 알을 깨고 나올 준비를 하고 있어요.".formatted(beforeCharacterName);

		notificationRepository.save(Notification.of(
				userId, NotificationType.TAMAGOTCHI_FAREWELL, title, body, userCharacterId));

		LocalTime now = LocalTime.now(ZoneId.of("Asia/Seoul"));
		dispatchFcm(userId, now, title, body, "[tamagotchi-farewell]");
	}

	@Override
	public void sendTamagotchiGrowth(Long userId, Long userCharacterId, String characterName, String afterStage) {
		String title = "다마고치가 성장했어요!";
		String body  = "\"%s\"이(가) %s 단계로 성장했어요.".formatted(characterName, afterStage);

		notificationRepository.save(Notification.of(
				userId, NotificationType.TAMAGOTCHI_GROWTH, title, body, userCharacterId));

		LocalTime now = LocalTime.now(ZoneId.of("Asia/Seoul"));
		dispatchFcm(userId, now, title, body, "[tamagotchi-growth]");
	}

	/**
	 * DND 체크 → 토큰 조회 → FCM 발송 공통 처리.
	 * DB 저장은 호출 측(sendXxx)에서 먼저 수행 후 이 메서드를 호출한다.
	 */
	private void dispatchFcm(Long userId, LocalTime now, String title, String body, String logTag) {
		boolean inDnd = userSettingRepository.findByUserId(userId)
				.map(s -> isInDnd(s, now))
				.orElse(false);
		if (inDnd) {
			log.debug("{} dnd; fcm skipped user={}", logTag, userId);
			return;
		}

		List<DeviceToken> tokens = deviceTokenRepository.findAllByUserIdAndIsActiveTrue(userId);
		if (tokens.isEmpty()) return;

		try {
			fcmService.send(tokens, title, body);
		} catch (Exception ex) {
			log.warn("{} fcm failed user={}", logTag, userId, ex);
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
