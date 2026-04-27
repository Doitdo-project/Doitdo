package com.doitdo.domain.todo.application.impl;

import com.doitdo.domain.todo.entity.Todo;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;

public final class CalendarOccurrenceGenerator {

	private CalendarOccurrenceGenerator() {}

	public static List<LocalDate> generate(Todo master, LocalDate from, LocalDate to) {
		Set<DayOfWeek> daysOfWeek = master.getDaysOfWeek();
		if (daysOfWeek.isEmpty()) {
			return List.of();
		}

		LocalDate cursor = from.isBefore(master.getStartDate()) ? master.getStartDate() : from;
		LocalDate endBoundary = master.getEndDate() != null && master.getEndDate().isBefore(to)
				? master.getEndDate()
				: to;
		List<LocalDate> occurrences = new ArrayList<>();

		while (!cursor.isAfter(endBoundary)) {
			if (daysOfWeek.contains(cursor.getDayOfWeek())) {
				occurrences.add(cursor);
			}
			cursor = cursor.plusDays(1);
		}

		return occurrences;
	}
}
