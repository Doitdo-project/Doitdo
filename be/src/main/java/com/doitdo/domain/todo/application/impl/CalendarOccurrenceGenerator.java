package com.doitdo.domain.todo.application.impl;

import com.doitdo.domain.todo.entity.Todo;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

public final class CalendarOccurrenceGenerator {

	private CalendarOccurrenceGenerator() {}

	public static List<LocalDate> generate(Todo master, LocalDate from, LocalDate to) {
		if (master.getPeriod() == null || master.getPeriod() <= 0) {
			return List.of();
		}

		LocalDate cursor = master.getStartDate();
		LocalDate endBoundary = master.getEndDate();
		List<LocalDate> occurrences = new ArrayList<>();

		while (cursor.isBefore(from)) {
			cursor = cursor.plusDays(master.getPeriod());
			if (endBoundary != null && cursor.isAfter(endBoundary)) {
				return List.of();
			}
		}

		while (!cursor.isAfter(to)) {
			if (endBoundary != null && cursor.isAfter(endBoundary)) {
				break;
			}
			occurrences.add(cursor);
			cursor = cursor.plusDays(master.getPeriod());
		}

		return occurrences;
	}
}
