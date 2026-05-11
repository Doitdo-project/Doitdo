package com.doitdo.domain.todo.application.scheduler;

import com.doitdo.domain.todo.entity.Todo;
import com.doitdo.domain.todo.entity.Todo.TodoType;
import com.doitdo.domain.todo.repository.TodoRepository;
import com.doitdo.global.cache.CacheEvictHelper;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@RequiredArgsConstructor
public class RecurrenceMaterializeScheduler {

	private static final ZoneId SEOUL = ZoneId.of("Asia/Seoul");

	private final TodoRepository todoRepository;
	private final CacheEvictHelper cacheEvictHelper;

	@Scheduled(cron = "0 0 0 * * *", zone = "Asia/Seoul")
	public void run() {
		materialize(LocalDate.now(SEOUL));
	}

	void materialize(LocalDate today) {
		List<Todo> masters = todoRepository.findAllByTypeAndIsDeletedFalse(TodoType.RECURRING);
		int created = 0;
		int skipped = 0;
		int failed = 0;
		Set<Long> affectedUserIds = new HashSet<>();

		for (Todo master : masters) {
			if (!isDue(master, today)) {
				continue;
			}
			if (todoRepository.findByUserIdAndMasterTodoIdAndStartDateAndIsDeletedFalse(
					master.getUserId(), master.getTodoId(), today).isPresent()) {
				skipped++;
				continue;
			}

			try {
				todoRepository.saveAndFlush(Todo.createRecurringInstance(master, today));
				affectedUserIds.add(master.getUserId());
				created++;
			} catch (DataIntegrityViolationException ex) {
				skipped++;
				log.warn("[recurrence-materialize] duplicate skipped masterTodoId={} date={}",
						master.getTodoId(), today);
			} catch (RuntimeException ex) {
				failed++;
				log.warn("[recurrence-materialize] failed masterTodoId={} date={}", master.getTodoId(), today, ex);
			}
		}
		affectedUserIds.forEach(cacheEvictHelper::evictUserTodos);

		log.info("[recurrence-materialize] date={} masters={} created={} skipped={} failed={}",
				today, masters.size(), created, skipped, failed);
	}

	private boolean isDue(Todo master, LocalDate today) {
		if (today.isBefore(master.getStartDate())) {
			return false;
		}
		if (master.getEndDate() != null && today.isAfter(master.getEndDate())) {
			return false;
		}
		return master.getDaysOfWeek().contains(today.getDayOfWeek());
	}
}
