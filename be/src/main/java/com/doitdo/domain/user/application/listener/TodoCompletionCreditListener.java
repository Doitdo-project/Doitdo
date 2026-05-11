package com.doitdo.domain.user.application.listener;

import com.doitdo.domain.todo.entity.Todo;
import com.doitdo.domain.todo.event.TodoCompletedEvent;
import com.doitdo.domain.todo.repository.TodoRepository;
import com.doitdo.domain.user.application.CreditEarnService;
import com.doitdo.domain.user.entity.WalletEarnSource;
import com.doitdo.domain.user.repository.WalletEarnLogRepository;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

/**
 * TODO DONE 전이 이벤트를 구독해 TODO 완료 3개당 10 뚜레딧을 적립한다.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class TodoCompletionCreditListener {

	private static final ZoneId SEOUL = ZoneId.of("Asia/Seoul");
	private static final int TODO_COMPLETION_CREDIT = 10;
	private static final int REQUIRED_COMPLETION_COUNT = 3;

	private final TodoRepository todoRepository;
	private final WalletEarnLogRepository walletEarnLogRepository;
	private final CreditEarnService creditEarnService;

	@TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
	@Transactional(propagation = Propagation.REQUIRES_NEW)
	public void onTodoCompleted(TodoCompletedEvent event) {
		LocalDate today = LocalDate.now(SEOUL);
		Todo todo = todoRepository.findByTodoIdAndIsDeletedFalse(event.todoId())
				.orElse(null);
		if (todo == null) {
			log.debug("[credit] todo not found; skipped todoId={}", event.todoId());
			return;
		}
		if (!isRewardEligible(todo, today)) {
			log.debug("[credit] past todo; skipped todoId={}", event.todoId());
			return;
		}

		long todayDistinctFirstCompleted = todoRepository.countRewardEligibleByUserIdAndFirstCompletedDate(
				event.userId(),
				today
		);
		int todayEarnCount = todayTodoCompletionEarnAmount(event.userId(), today) / TODO_COMPLETION_CREDIT;

		if ((long) (todayEarnCount + 1) * REQUIRED_COMPLETION_COUNT > todayDistinctFirstCompleted) {
			log.debug("[credit] todo completion threshold not reached; user={} todo={} distinct={} earnCount={}",
					event.userId(), event.todoId(), todayDistinctFirstCompleted, todayEarnCount);
			return;
		}

		int earnedAmount = creditEarnService.tryEarn(
				event.userId(),
				WalletEarnSource.TODO_COMPLETION,
				TODO_COMPLETION_CREDIT,
				event.todoId(),
				false
		);
		log.debug("[credit] todo completion evaluated; user={} todo={} earnedAmount={}",
				event.userId(), event.todoId(), earnedAmount);
	}

	private boolean isRewardEligible(Todo todo, LocalDate today) {
		LocalDate criteriaDate = switch (todo.getType()) {
			case SOMEDAY -> null;
			case PERIOD -> todo.getEndDate() != null ? todo.getEndDate() : todo.getStartDate();
			default -> todo.getStartDate();
		};
		return criteriaDate == null || !criteriaDate.isBefore(today);
	}

	private int todayTodoCompletionEarnAmount(Long userId, LocalDate today) {
		LocalDateTime startOfDay = today.atStartOfDay();
		LocalDateTime endOfDay = today.plusDays(1).atStartOfDay();
		return walletEarnLogRepository.sumAmountByUserIdAndSourceAndDate(
				userId,
				WalletEarnSource.TODO_COMPLETION,
				startOfDay,
				endOfDay
		);
	}
}
