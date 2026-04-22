package com.doitdo.domain.notification.application.scheduler;

import com.doitdo.domain.notification.application.FcmService;
import com.doitdo.domain.notification.repository.DeviceTokenRepository;
import com.doitdo.domain.notification.repository.NotificationRepository;
import com.doitdo.domain.todo.repository.TodoRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnBean;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@RequiredArgsConstructor
@ConditionalOnBean(type = "com.doitdo.domain.setting.repository.NotificationSettingRepository")
public class EveningReminderScheduler {

	@SuppressWarnings("unused")
	private final TodoRepository todoRepository;

	@SuppressWarnings("unused")
	private final NotificationRepository notificationRepository;

	@SuppressWarnings("unused")
	private final DeviceTokenRepository deviceTokenRepository;

	@SuppressWarnings("unused")
	private final FcmService fcmService;

	@Scheduled(cron = "0 * * * * *")
	public void run() {
		// NotificationSetting 도메인 머지 후 실제 조회/발송 로직을 연결한다.
		log.debug("[notification-scheduler] NotificationSettingRepository detected; integration TODO.");
	}
}
