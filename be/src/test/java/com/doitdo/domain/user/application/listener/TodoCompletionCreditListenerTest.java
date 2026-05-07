package com.doitdo.domain.user.application.listener;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;

import com.doitdo.domain.todo.event.TodoCompletedEvent;
import com.doitdo.domain.todo.repository.TodoRepository;
import com.doitdo.domain.user.application.CreditEarnService;
import com.doitdo.domain.user.entity.WalletEarnSource;
import com.doitdo.domain.user.repository.WalletEarnLogRepository;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicLong;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class TodoCompletionCreditListenerTest {

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
	void skipsSameTodoUndoRedoWhenOnlyOneDistinctTodoWasFirstCompletedToday() {
		given(todoRepository.countByUserIdAndFirstCompletedDate(eq(1L), any(LocalDate.class))).willReturn(1L);
		given(walletEarnLogRepository.sumAmountByUserIdAndSourceAndDate(
				eq(1L),
				eq(WalletEarnSource.TODO_COMPLETION),
				any(LocalDateTime.class),
				any(LocalDateTime.class)
		)).willReturn(0);

		for (int i = 0; i < 5; i++) {
			listener.onTodoCompleted(new TodoCompletedEvent(1L, 10L));
		}

		verify(creditEarnService, never()).tryEarn(
				eq(1L),
				eq(WalletEarnSource.TODO_COMPLETION),
				eq(10),
				eq(10L),
				eq(false)
		);
	}

	@Test
	void earnsThreeTimesForNineDistinctTodosAndDoesNotEarnOnTenthTodo() {
		AtomicLong todayDistinctFirstCompleted = new AtomicLong();
		AtomicInteger todayEarnCount = new AtomicInteger();
		given(todoRepository.countByUserIdAndFirstCompletedDate(eq(1L), any(LocalDate.class)))
				.willAnswer(invocation -> todayDistinctFirstCompleted.get());
		given(walletEarnLogRepository.sumAmountByUserIdAndSourceAndDate(
				eq(1L),
				eq(WalletEarnSource.TODO_COMPLETION),
				any(LocalDateTime.class),
				any(LocalDateTime.class)
		)).willAnswer(invocation -> todayEarnCount.get() * 10);
		given(creditEarnService.tryEarn(
				eq(1L),
				eq(WalletEarnSource.TODO_COMPLETION),
				eq(10),
				any(Long.class),
				eq(false)
		)).willAnswer(invocation -> {
			todayEarnCount.incrementAndGet();
			return 10;
		});

		for (long completedCount = 1; completedCount <= 10; completedCount++) {
			todayDistinctFirstCompleted.set(completedCount);
			listener.onTodoCompleted(new TodoCompletedEvent(1L, completedCount));
		}

		assertThat(todayEarnCount.get()).isEqualTo(3);
		verify(creditEarnService, times(3)).tryEarn(
				eq(1L),
				eq(WalletEarnSource.TODO_COMPLETION),
				eq(10),
				any(Long.class),
				eq(false)
		);
	}

	@Test
	void earnsWhenThirdDistinctTodoPassesThresholdWithDailyCapEnabled() {
		given(todoRepository.countByUserIdAndFirstCompletedDate(eq(1L), any(LocalDate.class))).willReturn(3L);
		given(walletEarnLogRepository.sumAmountByUserIdAndSourceAndDate(
				eq(1L),
				eq(WalletEarnSource.TODO_COMPLETION),
				any(LocalDateTime.class),
				any(LocalDateTime.class)
		)).willReturn(0);
		given(creditEarnService.tryEarn(1L, WalletEarnSource.TODO_COMPLETION, 10, 3L, false))
				.willReturn(10);

		listener.onTodoCompleted(new TodoCompletedEvent(1L, 3L));

		verify(creditEarnService).tryEarn(1L, WalletEarnSource.TODO_COMPLETION, 10, 3L, false);
	}
}
