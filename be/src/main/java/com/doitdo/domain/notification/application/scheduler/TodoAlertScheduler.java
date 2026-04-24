package com.doitdo.domain.notification.application.scheduler;

import com.doitdo.domain.notification.application.FcmService;
import com.doitdo.domain.notification.entity.DeviceToken;
import com.doitdo.domain.notification.repository.DeviceTokenRepository;
import com.doitdo.domain.todo.entity.Todo;
import com.doitdo.domain.todo.repository.TodoRepository;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
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
	private final DeviceTokenRepository deviceTokenRepository;
	private final FcmService fcmService;

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

		// userId 별 DeviceToken 캐싱 (같은 분에 여러 TODO 가 있어도 토큰을 반복 조회하지 않음)
		Map<Long, List<DeviceToken>> tokenCache = new HashMap<>();

		for (Todo todo : targets) {
			Long userId = todo.getUserId();
			List<DeviceToken> tokens = tokenCache.computeIfAbsent(
					userId,
					id -> deviceTokenRepository.findAllByUserIdAndIsActiveTrue(id)
			);

			if (tokens.isEmpty()) {
				continue;
			}

			try {
				fcmService.send(tokens, "할 일 알림", "📌 " + todo.getTitle());
				log.debug("[todo-alert] 발송 완료 userId={} todoId={}", userId, todo.getTodoId());
			} catch (Exception ex) {
				log.warn("[todo-alert] 발송 실패 userId={} todoId={}", userId, todo.getTodoId(), ex);
			}
		}
	}
}
