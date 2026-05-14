package com.doitdo.domain.notification.application.impl;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.BDDMockito.given;
import static org.mockito.BDDMockito.then;

import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.doitdo.domain.notification.api.dto.req.TestNotificationSendReq;
import com.doitdo.domain.notification.application.FcmService;
import com.doitdo.domain.notification.entity.DeviceToken;
import com.doitdo.domain.notification.entity.Notification;
import com.doitdo.domain.notification.entity.Notification.NotificationType;
import com.doitdo.domain.notification.repository.DeviceTokenRepository;
import com.doitdo.domain.notification.repository.NotificationRepository;
import com.doitdo.domain.setting.repository.UserSettingRepository;

@ExtendWith(MockitoExtension.class)
class NotificationServiceImplTest {

	@Mock
	private NotificationRepository notificationRepository;

	@Mock
	private UserSettingRepository userSettingRepository;

	@Mock
	private DeviceTokenRepository deviceTokenRepository;

	@Mock
	private FcmService fcmService;

	@Test
	void sendTestNotificationSavesNotificationAndSendsFcmImmediately() {
		NotificationServiceImpl service = new NotificationServiceImpl(
				notificationRepository, userSettingRepository, deviceTokenRepository, fcmService);
		TestNotificationSendReq req = new TestNotificationSendReq("테스트 알림", "모바일 푸시 테스트입니다.");
		List<DeviceToken> tokens = List.of(DeviceToken.create(1L, "fcm-token", DeviceToken.Platform.ANDROID));
		given(deviceTokenRepository.findAllByUserIdAndIsActiveTrue(1L)).willReturn(tokens);
		given(fcmService.send(tokens, req.title(), req.message()))
				.willReturn(new FcmService.SendResult(1, List.of()));

		service.sendTestNotification(1L, req);

		ArgumentCaptor<Notification> captor = ArgumentCaptor.forClass(Notification.class);
		then(notificationRepository).should().save(captor.capture());
		Notification saved = captor.getValue();
		assertThat(saved.getUserId()).isEqualTo(1L);
		assertThat(saved.getType()).isEqualTo(NotificationType.REMINDER_EVENING);
		assertThat(saved.getTitle()).isEqualTo(req.title());
		assertThat(saved.getMessage()).isEqualTo(req.message());
		then(userSettingRepository).shouldHaveNoInteractions();
		then(fcmService).should().send(tokens, req.title(), req.message());
	}

	@Test
	void sendTestNotificationSavesNotificationEvenWithoutActiveTokens() {
		NotificationServiceImpl service = new NotificationServiceImpl(
				notificationRepository, userSettingRepository, deviceTokenRepository, fcmService);
		TestNotificationSendReq req = new TestNotificationSendReq("테스트 알림", "모바일 푸시 테스트입니다.");
		given(deviceTokenRepository.findAllByUserIdAndIsActiveTrue(1L)).willReturn(List.of());

		service.sendTestNotification(1L, req);

		then(notificationRepository).should().save(any(Notification.class));
		then(fcmService).shouldHaveNoInteractions();
	}

	@Test
	void sendTamagotchiGrowthUsesHatchTitleWhenAfterStageIsBaby() {
		NotificationServiceImpl service = new NotificationServiceImpl(
				notificationRepository, userSettingRepository, deviceTokenRepository, fcmService);
		given(deviceTokenRepository.findAllByUserIdAndIsActiveTrue(1L)).willReturn(List.of());

		service.sendTamagotchiGrowth(1L, 10L, "두잇", "BABY");

		ArgumentCaptor<Notification> captor = ArgumentCaptor.forClass(Notification.class);
		then(notificationRepository).should().save(captor.capture());
		Notification saved = captor.getValue();
		assertThat(saved.getType()).isEqualTo(NotificationType.TAMAGOTCHI_GROWTH);
		assertThat(saved.getTitle()).isEqualTo("알이 부화했어요!");
		assertThat(saved.getMessage()).isEqualTo("\"두잇\"이(가) BABY 단계로 성장했어요.");
	}

	@Test
	void sendTamagotchiFarewellSavesReadyMessage() {
		NotificationServiceImpl service = new NotificationServiceImpl(
				notificationRepository, userSettingRepository, deviceTokenRepository, fcmService);
		given(deviceTokenRepository.findAllByUserIdAndIsActiveTrue(1L)).willReturn(List.of());

		service.sendTamagotchiFarewell(1L, 10L, "두잇");

		ArgumentCaptor<Notification> captor = ArgumentCaptor.forClass(Notification.class);
		then(notificationRepository).should().save(captor.capture());
		Notification saved = captor.getValue();
		assertThat(saved.getUserId()).isEqualTo(1L);
		assertThat(saved.getType()).isEqualTo(NotificationType.TAMAGOTCHI_FAREWELL);
		assertThat(saved.getTitle()).isEqualTo("독립 준비 완료");
		assertThat(saved.getMessage()).isEqualTo("\"두잇\"이(가) 독립할 준비가 되었어요!");
		assertThat(saved.getReferenceId()).isEqualTo(10L);
	}

	@Test
	void sendStreakTodoEmptyReminderSavesStreakReminder() {
		NotificationServiceImpl service = new NotificationServiceImpl(
				notificationRepository, userSettingRepository, deviceTokenRepository, fcmService);
		given(notificationRepository.existsByUserIdAndTypeAndCreatedAtBetweenAndIsDeletedFalse(
				eq(1L), eq(NotificationType.REMINDER_STREAK_TODO_EMPTY), any(LocalDateTime.class), any(LocalDateTime.class)))
				.willReturn(false);
		given(deviceTokenRepository.findAllByUserIdAndIsActiveTrue(1L)).willReturn(List.of());

		service.sendStreakTodoEmptyReminder(1L, LocalTime.of(8, 0));

		ArgumentCaptor<Notification> captor = ArgumentCaptor.forClass(Notification.class);
		then(notificationRepository).should().save(captor.capture());
		Notification saved = captor.getValue();
		assertThat(saved.getUserId()).isEqualTo(1L);
		assertThat(saved.getType()).isEqualTo(NotificationType.REMINDER_STREAK_TODO_EMPTY);
		assertThat(saved.getTitle()).isEqualTo("오늘 할 일이 비어 있어요");
		assertThat(saved.getMessage()).isEqualTo("스트릭을 이어가려면 오늘 할 일을 하나 추가해봐요.");
	}
}
