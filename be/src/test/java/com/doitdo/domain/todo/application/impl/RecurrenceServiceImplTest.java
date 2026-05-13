package com.doitdo.domain.todo.application.impl;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;

import com.doitdo.domain.todo.api.dto.req.TodoCalendarReq;
import com.doitdo.domain.todo.api.dto.resp.TodoCalendarResp;
import com.doitdo.domain.todo.entity.Todo;
import com.doitdo.domain.todo.entity.Todo.TodoStatus;
import com.doitdo.domain.todo.entity.Todo.TodoType;
import com.doitdo.domain.todo.repository.CategoryRepository;
import com.doitdo.domain.todo.repository.PaletteColorRepository;
import com.doitdo.domain.todo.repository.SnoozeHistoryRepository;
import com.doitdo.domain.todo.repository.TodoRepository;
import java.time.LocalDate;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;

@ExtendWith(MockitoExtension.class)
class RecurrenceServiceImplTest {

	@Mock
	private TodoRepository todoRepository;

	@Mock
	private CategoryRepository categoryRepository;

	@Mock
	private PaletteColorRepository paletteColorRepository;

	@Mock
	private SnoozeHistoryRepository snoozeHistoryRepository;

	private RecurrenceServiceImpl service;

	@BeforeEach
	void setUp() {
		service = new RecurrenceServiceImpl(
				todoRepository,
				categoryRepository,
				paletteColorRepository,
				snoozeHistoryRepository);
	}

	@Test
	void calendarDoesNotCreateVirtualOccurrenceWhenDeletedRecurringInstanceMarkerExists() {
		LocalDate occurrenceDate = LocalDate.parse("2026-05-12");
		Todo master = recurringMaster();
		Todo deletedMarker = recurringInstance(master, occurrenceDate, true);
		given(todoRepository.findAll(any(Specification.class), any(Sort.class))).willReturn(List.of(master));
		given(todoRepository.findRecurringInstanceMarkers(
				1L,
				List.of(10L),
				occurrenceDate,
				occurrenceDate))
				.willReturn(List.of(deletedMarker));
		given(categoryRepository.findAllByUserIdOrderByCategoryIdAsc(1L)).willReturn(List.of());
		given(paletteColorRepository.findAll()).willReturn(List.of());
		given(snoozeHistoryRepository.countByTodoIdIn(any())).willReturn(List.of());
		given(snoozeHistoryRepository.findEarliestFromDateByTodoIdIn(any())).willReturn(List.of());

		TodoCalendarResp resp = service.calendar(
				1L,
				new TodoCalendarReq(occurrenceDate, occurrenceDate, null, null, null));

		assertThat(resp.items()).isEmpty();
	}

	private Todo recurringMaster() {
		return Todo.builder()
				.todoId(10L)
				.userId(1L)
				.title("repeat")
				.type(TodoType.RECURRING)
				.status(TodoStatus.TODO)
				.priority(1)
				.startDate(LocalDate.parse("2026-05-05"))
				.daysOfWeekRaw("TUE")
				.isDeleted(false)
				.expGranted(false)
				.build();
	}

	private Todo recurringInstance(Todo master, LocalDate occurrenceDate, boolean deleted) {
		return Todo.builder()
				.todoId(25L)
				.userId(master.getUserId())
				.title(master.getTitle())
				.type(TodoType.NORMAL)
				.status(TodoStatus.TODO)
				.priority(master.getPriority())
				.startDate(occurrenceDate)
				.masterTodoId(master.getTodoId())
				.isDeleted(deleted)
				.expGranted(false)
				.build();
	}
}
