package com.doitdo.domain.todo.api.dto.resp;

import com.doitdo.domain.todo.entity.Todo;
import com.doitdo.domain.todo.entity.Todo.TodoStatus;
import com.doitdo.domain.todo.entity.Todo.TodoType;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

public record TodoDetailResp(

		Long todoId,
		String title,
		String content,
		String category,
		String colorHex,
		TodoType type,
		Integer priority,
		String alertTime,
		LocalDate startDate,
		LocalDate endDate,
		List<String> daysOfWeek,
		TodoStatus status,
		LocalDateTime updatedAt,
		Long masterTodoId,
		Long recurrenceGroupId,
		LocalDate occurrenceDate,
		int snoozedDays,
		List<LocalDate> excludedDates,
		Integer earnedCoin,
		boolean rewarded,
		Integer walletBalance
) {

	public TodoDetailResp(
			Long todoId,
			String title,
			String content,
			String category,
			String colorHex,
			TodoType type,
			Integer priority,
			String alertTime,
			LocalDate startDate,
			LocalDate endDate,
			List<String> daysOfWeek,
			TodoStatus status,
			LocalDateTime updatedAt,
			Long masterTodoId,
			Long recurrenceGroupId,
			LocalDate occurrenceDate,
			int snoozedDays,
			List<LocalDate> excludedDates) {
		this(
				todoId,
				title,
				content,
				category,
				colorHex,
				type,
				priority,
				alertTime,
				startDate,
				endDate,
				daysOfWeek,
				status,
				updatedAt,
				masterTodoId,
				recurrenceGroupId,
				occurrenceDate,
				snoozedDays,
				excludedDates,
				0,
				false,
				null
		);
	}

	public static TodoDetailResp from(Todo todo, String categoryName, String colorHex, int snoozedDays) {
		return from(todo, categoryName, colorHex, snoozedDays, List.of());
	}

	public static TodoDetailResp from(
			Todo todo,
			String categoryName,
			String colorHex,
			int snoozedDays,
			List<LocalDate> excludedDates) {
		return new TodoDetailResp(
				todo.getTodoId(),
				todo.getTitle(),
				todo.getContent(),
				categoryName,
				colorHex,
				todo.getType(),
				todo.getPriority(),
				todo.getAlertTime(),
				todo.getStartDate(),
				todo.getEndDate(),
				todo.getDaysOfWeek().stream()
						.sorted()
						.map(Todo::toDayOfWeekCode)
						.toList(),
				todo.getStatus(),
				todo.getUpdatedAt(),
				todo.getMasterTodoId(),
				todo.getRecurrenceGroupId(),
				todo.getMasterTodoId() != null ? todo.getStartDate() : null,
				snoozedDays,
				excludedDates
		);
	}

	public TodoDetailResp withReward(Integer earnedCoin, boolean rewarded, Integer walletBalance) {
		return new TodoDetailResp(
				todoId,
				title,
				content,
				category,
				colorHex,
				type,
				priority,
				alertTime,
				startDate,
				endDate,
				daysOfWeek,
				status,
				updatedAt,
				masterTodoId,
				recurrenceGroupId,
				occurrenceDate,
				snoozedDays,
				excludedDates,
				earnedCoin,
				rewarded,
				walletBalance
		);
	}
}
