package com.doitdo.domain.todo.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.LocalDate;
import java.time.LocalDateTime;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Getter
@Table(name = "snooze_history")
@Builder
@AllArgsConstructor(access = AccessLevel.PRIVATE)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class SnoozeHistory {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	@Column(name = "snooze_history_id")
	private Long snoozeHistoryId;

	@Column(name = "todo_id", nullable = false)
	private Long todoId;

	@Column(name = "user_id", nullable = false)
	private Long userId;

	@Column(name = "snoozed_at", nullable = false)
	private LocalDateTime snoozedAt;

	@Column(name = "from_date", nullable = false)
	private LocalDate fromDate;

	@Column(name = "to_date", nullable = false)
	private LocalDate toDate;

	public static SnoozeHistory create(Long todoId, Long userId, LocalDate fromDate, LocalDate toDate) {
		return SnoozeHistory.builder()
				.todoId(todoId)
				.userId(userId)
				.snoozedAt(LocalDateTime.now())
				.fromDate(fromDate)
				.toDate(toDate)
				.build();
	}
}
