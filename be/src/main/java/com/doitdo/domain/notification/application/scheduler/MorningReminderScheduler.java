package com.doitdo.domain.notification.application.scheduler;

import com.doitdo.domain.notification.application.NotificationService;
import com.doitdo.domain.setting.entity.UserSetting;
import com.doitdo.domain.setting.repository.UserSettingRepository;
import com.doitdo.domain.streak.entity.UserStreak;
import com.doitdo.domain.streak.repository.UserStreakRepository;
import com.doitdo.domain.todo.repository.TodoRepository;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.ZoneId;
import java.util.List;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@RequiredArgsConstructor
@ConditionalOnProperty(
		name = "notification.morning-reminder.enabled",
		havingValue = "true",
		matchIfMissing = true)
public class MorningReminderScheduler {

	private final UserSettingRepository userSettingRepository;
	private final TodoRepository todoRepository;
	private final UserStreakRepository userStreakRepository;
	private final NotificationService notificationService;

	@Scheduled(cron = "0 * * * * *", zone = "Asia/Seoul")
	public void run() {
		ZoneId zone = ZoneId.of("Asia/Seoul");
		LocalTime now = LocalTime.now(zone).withSecond(0).withNano(0);
		LocalDate today = LocalDate.now(zone);

		List<UserSetting> targets =
				userSettingRepository.findAllByMorningReminderEnabledTrueAndMorningReminderTime(now);

		for (UserSetting s : targets) {
			long pending = todoRepository.countPendingByUserIdAndToday(s.getUserId(), today);
			if (pending > 0) {
				try {
					notificationService.sendMorningReminder(s.getUserId(), (int) pending, now);
				} catch (Exception ex) {
					log.warn("[morning-reminder] send failed user={}", s.getUserId(), ex);
				}
				continue;
			}

			long todayTodos = todoRepository.countActiveByUserIdAndToday(s.getUserId(), today);
			if (todayTodos > 0 || !canContinueStreak(s.getUserId(), today)) {
				continue;
			}

			try {
				notificationService.sendStreakTodoEmptyReminder(s.getUserId(), now);
			} catch (Exception ex) {
				log.warn("[streak-todo-empty-reminder] send failed user={}", s.getUserId(), ex);
			}
		}
	}

	private boolean canContinueStreak(Long userId, LocalDate today) {
		return userStreakRepository.findByUserId(userId)
				.filter(streak -> isContinuable(streak, today))
				.isPresent();
	}

	private boolean isContinuable(UserStreak streak, LocalDate today) {
		return streak.getCurrentStreakCount() != null
				&& streak.getCurrentStreakCount() > 0
				&& today.minusDays(1).equals(streak.getLastActiveDate());
	}
}
