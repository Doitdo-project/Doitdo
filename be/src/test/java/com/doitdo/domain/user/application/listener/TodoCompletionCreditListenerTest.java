package com.doitdo.domain.user.application.listener;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;

import com.doitdo.domain.todo.entity.Todo;
import com.doitdo.domain.todo.event.TodoCompletedEvent;
import com.doitdo.domain.todo.repository.TodoRepository;
import com.doitdo.domain.user.application.CreditEarnService;
import com.doitdo.domain.user.entity.WalletEarnSource;
import com.doitdo.domain.user.repository.WalletEarnLogRepository;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.Optional;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicLong;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class TodoCompletionCreditListenerTest {

	private static final ZoneId SEOUL = ZoneId.of("Asia/Seoul");

	@Mock
	private TodoRepository todoRepository;

	@Mock
	private WalletEarnLogRepository walletEarnLogRepository;

	@Mock
	private CreditEarnService creditEarnService;

	private TodoCompletionCreditListener listener;

	@BeforeEach
	void setUp() {
		listener = new TodoCompletionCreditListener(todoRepository, walletEarnLogRepository, creditEarnService);
	}

	@Test
	void earnsOnceForSameTodoUndoRedoWhenOnlyOneDistinctTodoWasFirstCompletedToday() {
		AtomicInteger todayEarnCount = new AtomicInteger();
		given(todoRepository.findByTodoIdAndIsDeletedFalse(10L))
				.willReturn(Optional.of(normalTodo(LocalDate.now(SEOUL))));
		given(todoRepository.countRewardEligibleByUserIdAndFirstCompletedDate(eq(1L), any(LocalDate.class)))
				.willReturn(1L);
		given(walletEarnLogRepository.sumAmountByUserIdAndSourceAndDate(
				eq(1L),
				eq(WalletEarnSource.TODO_COMPLETION),
				any(LocalDateTime.class),
				any(LocalDateTime.class)
		)).willAnswer(invocation -> todayEarnCount.get() * 20);
		given(creditEarnService.tryEarn(
				eq(1L),
				eq(WalletEarnSource.TODO_COMPLETION),
				eq(20),
				eq(10L),
				eq(false)
		)).willAnswer(invocation -> {
			todayEarnCount.incrementAndGet();
			return 20;
		});

		for (int i = 0; i < 5; i++) {
			listener.onTodoCompleted(new TodoCompletedEvent(1L, 10L));
		}

		assertThat(todayEarnCount.get()).isEqualTo(1);
		verify(creditEarnService, times(1)).tryEarn(
				eq(1L),
				eq(WalletEarnSource.TODO_COMPLETION),
				eq(20),
				eq(10L),
				eq(false)
		);
	}

	@Test
	void attemptsEarnForEachNewDistinctTodoAndDelegatesSixthToDailyCap() {
		AtomicLong todayDistinctFirstCompleted = new AtomicLong();
		AtomicInteger todayEarnCount = new AtomicInteger();
		AtomicInteger attemptCount = new AtomicInteger();
		given(todoRepository.findByTodoIdAndIsDeletedFalse(any(Long.class)))
				.willReturn(Optional.of(normalTodo(LocalDate.now(SEOUL))));
		given(todoRepository.countRewardEligibleByUserIdAndFirstCompletedDate(eq(1L), any(LocalDate.class)))
				.willAnswer(invocation -> todayDistinctFirstCompleted.get());
		given(walletEarnLogRepository.sumAmountByUserIdAndSourceAndDate(
				eq(1L),
				eq(WalletEarnSource.TODO_COMPLETION),
				any(LocalDateTime.class),
				any(LocalDateTime.class)
		)).willAnswer(invocation -> todayEarnCount.get() * 20);
		given(creditEarnService.tryEarn(
				eq(1L),
				eq(WalletEarnSource.TODO_COMPLETION),
				eq(20),
				any(Long.class),
				eq(false)
		)).willAnswer(invocation -> {
			int attempts = attemptCount.incrementAndGet();
			if (attempts > 5) {
				return 0;
			}
			todayEarnCount.incrementAndGet();
			return 20;
		});

		for (long completedCount = 1; completedCount <= 6; completedCount++) {
			todayDistinctFirstCompleted.set(completedCount);
			listener.onTodoCompleted(new TodoCompletedEvent(1L, completedCount));
		}

		assertThat(todayEarnCount.get()).isEqualTo(5);
		verify(creditEarnService, times(6)).tryEarn(
				eq(1L),
				eq(WalletEarnSource.TODO_COMPLETION),
				eq(20),
				any(Long.class),
				eq(false)
		);
	}

	@Test
	void earnsWhenFirstDistinctTodoPassesThresholdWithDailyCapEnabled() {
		given(todoRepository.findByTodoIdAndIsDeletedFalse(1L))
				.willReturn(Optional.of(normalTodo(LocalDate.now(SEOUL))));
		given(todoRepository.countRewardEligibleByUserIdAndFirstCompletedDate(eq(1L), any(LocalDate.class)))
				.willReturn(1L);
		given(walletEarnLogRepository.sumAmountByUserIdAndSourceAndDate(
				eq(1L),
				eq(WalletEarnSource.TODO_COMPLETION),
				any(LocalDateTime.class),
				any(LocalDateTime.class)
		)).willReturn(0);
		given(creditEarnService.tryEarn(1L, WalletEarnSource.TODO_COMPLETION, 20, 1L, false))
				.willReturn(20);

		listener.onTodoCompleted(new TodoCompletedEvent(1L, 1L));

		verify(creditEarnService).tryEarn(1L, WalletEarnSource.TODO_COMPLETION, 20, 1L, false);
	}

	@Test
	void skipsWhenPastTodosAreExcludedFromEligibleCompletionCount() {
		given(todoRepository.findByTodoIdAndIsDeletedFalse(10L))
				.willReturn(Optional.of(normalTodo(LocalDate.now(SEOUL).minusDays(1))));

		listener.onTodoCompleted(new TodoCompletedEvent(1L, 10L));

		verify(todoRepository, never())
				.countRewardEligibleByUserIdAndFirstCompletedDate(eq(1L), any(LocalDate.class));
		verify(creditEarnService, never()).tryEarn(
				eq(1L),
				eq(WalletEarnSource.TODO_COMPLETION),
				eq(20),
				eq(10L),
				eq(false)
		);
	}

	private Todo normalTodo(LocalDate startDate) {
		return Todo.builder()
				.userId(1L)
				.categoryId(null)
				.title("test")
				.content(null)
				.type(Todo.TodoType.NORMAL)
				.status(Todo.TodoStatus.DONE)
				.priority(1)
				.startDate(startDate)
				.endDate(null)
				.isDeleted(false)
				.expGranted(false)
				.build();
	}
}
