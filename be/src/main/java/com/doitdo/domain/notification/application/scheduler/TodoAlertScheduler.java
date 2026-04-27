package com.doitdo.domain.notification.application.scheduler;

import com.doitdo.domain.notification.application.NotificationService;
import com.doitdo.domain.todo.entity.Todo;
import com.doitdo.domain.todo.repository.TodoRepository;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@RequiredArgsConstructor
public class TodoAlertScheduler {

	private static final ZoneId SEOUL = ZoneId.of("Asia/Seoul");
	private static final DateTimeFormatter HH_MM = DateTimeFormatter.ofPattern("HH:mm");

	private final TodoRepository todoRepository;
	private final NotificationService notificationService;

	@Scheduled(cron = "0 * * * * *", zone = "Asia/Seoul")
	public void run() {
		ZonedDateTime now = ZonedDateTime.now(SEOUL);
		String hhmm = now.format(HH_MM);
		LocalDate today = now.toLocalDate();

		List<Todo> targets = todoRepository.findAlertTargets(hhmm, today);
		if (targets.isEmpty()) {
			return;
		}

		log.debug("[todo-alert] {} 기준 알림 대상 {} 건", hhmm, targets.size());

		for (Todo todo : targets) {
			try {
				notificationService.sendTodoAlert(todo.getUserId(), todo.getTodoId(), todo.getTitle());
				log.debug("[todo-alert] 발송 완료 userId={} todoId={}", todo.getUserId(), todo.getTodoId());
			} catch (Exception ex) {
				log.warn("[todo-alert] 발송 실패 userId={} todoId={}", todo.getUserId(), todo.getTodoId(), ex);
			}
		}
	}
}
