package com.doitdo.domain.notification.application.scheduler;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.BDDMockito.then;
import static org.mockito.Mockito.mock;

import com.doitdo.domain.notification.application.NotificationService;
import com.doitdo.domain.setting.entity.UserSetting;
import com.doitdo.domain.setting.repository.UserSettingRepository;
import com.doitdo.domain.todo.repository.TodoRepository;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;
import org.junit.jupiter.api.Test;

class MorningReminderSchedulerTest {

	@Test
	void runCountsOnlyTodayPendingTodosForMorningReminder() {
		UserSettingRepository userSettingRepository = mock(UserSettingRepository.class);
		TodoRepository todoRepository = mock(TodoRepository.class);
		NotificationService notificationService = mock(NotificationService.class);
		MorningReminderScheduler scheduler =
				new MorningReminderScheduler(userSettingRepository, todoRepository, notificationService);
		UserSetting setting = UserSetting.builder()
				.userId(1L)
				.dndEnabled(false)
				.morningReminderEnabled(true)
				.morningReminderTime(LocalTime.of(8, 0))
				.eveningReminderEnabled(false)
				.eveningReminderTime(LocalTime.of(21, 0))
				.homeScreenMode(UserSetting.HomeScreenMode.HOME)
				.build();
		given(userSettingRepository.findAllByMorningReminderEnabledTrueAndMorningReminderTime(any(LocalTime.class)))
				.willReturn(List.of(setting));
		given(todoRepository.countPendingByUserIdAndToday(any(Long.class), any(LocalDate.class))).willReturn(2L);

		scheduler.run();

		then(todoRepository).should().countPendingByUserIdAndToday(any(Long.class), any(LocalDate.class));
		then(notificationService).should().sendMorningReminder(any(Long.class), any(Integer.class), any(LocalTime.class));
	}
}
