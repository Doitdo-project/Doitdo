package com.doitdo.domain.todo.entity;

import java.time.LocalDate;
import java.time.DayOfWeek;
import java.util.Arrays;
import java.util.EnumSet;
import java.util.Locale;
import java.util.Set;
import java.util.stream.Collectors;

import com.doitdo.global.entity.BaseTimeEntity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Transient;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Getter
@Table(name = "todos")
@Builder
@AllArgsConstructor(access = AccessLevel.PRIVATE)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Todo extends BaseTimeEntity {

	public enum TodoType { NORMAL, SOMEDAY, RECURRING, PERIOD }

	public enum TodoStatus { TODO, IN_PROGRESS, DONE }

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	@Column(name = "todo_id")
	private Long todoId;

	@Column(name = "user_id", nullable = false)
	private Long userId;

	@Column(name = "category_id")
	private Long categoryId;

	@Column(nullable = false, length = 20)
	private String title;

	@Column(length = 100)
	private String content;

	@Enumerated(EnumType.STRING)
	@Column(nullable = false, length = 20)
	private TodoType type;

	@Enumerated(EnumType.STRING)
	@Column(nullable = false, length = 20)
	private TodoStatus status;

	@Column(nullable = false)
	private Integer priority;

	@Column(name = "alert_time", length = 5)
	private String alertTime;

	@Column(name = "start_date")
	private LocalDate startDate;

	@Column(name = "end_date")
	private LocalDate endDate;

	@Column(name = "master_todo_id")
	private Long masterTodoId;

	@Column(name = "days_of_week", length = 27)
	private String daysOfWeekRaw;

	@Column(name = "is_deleted", nullable = false)
	private Boolean isDeleted;

	/**
	 * DONE 전이 시 Tamagotchi 경험치가 이미 지급됐는지 여부.
	 * 생애주기 동안 최초 1회만 true 로 세팅되어, 같은 Todo 재완료 시 중복 지급 차단.
	 */
	@Column(name = "exp_granted", nullable = false)
	private Boolean expGranted;

	public void softDelete() {
		this.isDeleted = true;
	}

	public void changeStatus(TodoStatus status) {
		this.status = status;
	}

	/** 경험치 지급 완료 마킹. 멱등 (이미 true 면 no-op). */
	public void markExpGranted() {
		this.expGranted = true;
	}

	public void changePriority(Integer priority) {
		this.priority = priority;
	}

	public void clearAlertTime() {
		this.alertTime = null;
	}

	public void snooze() {
		this.startDate = this.startDate.plusDays(1);
		if (this.endDate != null) {
			this.endDate = this.endDate.plusDays(1);
		}
	}

	@Transient
	public Set<DayOfWeek> getDaysOfWeek() {
		if (daysOfWeekRaw == null || daysOfWeekRaw.isBlank()) {
			return Set.of();
		}
		return Arrays.stream(daysOfWeekRaw.split(","))
				.map(String::trim)
				.filter(token -> !token.isEmpty())
				.map(Todo::toDayOfWeek)
				.collect(Collectors.toCollection(() -> EnumSet.noneOf(DayOfWeek.class)));
	}

	public void setDaysOfWeek(Set<DayOfWeek> daysOfWeek) {
		this.daysOfWeekRaw = toRawDaysOfWeek(daysOfWeek);
	}

	public void update(
			String title,
			String content,
			Long categoryId,
			TodoType type,
			LocalDate startDate,
			LocalDate endDate,
			Set<DayOfWeek> daysOfWeek,
			String alertTime) {
		if (title != null) this.title = title;
		this.content = content;
		if (categoryId != null) this.categoryId = categoryId;
		if (type != null) this.type = type;
		if (type == TodoType.SOMEDAY) {
			this.startDate = startDate;
		} else if (startDate != null) {
			this.startDate = startDate;
		}
		if (endDate != null) this.endDate = endDate;
		if (daysOfWeek != null) setDaysOfWeek(daysOfWeek);
		if (alertTime != null) this.alertTime = alertTime;
	}

	public static Todo create(
			Long userId,
			Long categoryId,
			String title,
			String content,
			TodoType type,
			Integer priority,
			String alertTime,
			LocalDate startDate,
			LocalDate endDate,
			Set<DayOfWeek> daysOfWeek) {
		return Todo.builder()
				.userId(userId)
				.categoryId(categoryId)
				.title(title)
				.content(content)
				.type(type)
				.status(TodoStatus.TODO)
				.priority(priority)
				.alertTime(alertTime)
				.startDate(type == TodoType.SOMEDAY ? null : startDate)
				.endDate(endDate)
				.masterTodoId(null)
				.daysOfWeekRaw(toRawDaysOfWeek(daysOfWeek))
				.isDeleted(false)
				.expGranted(false)
				.build();
	}

	public static Todo createRecurringInstance(Todo master, LocalDate occurrenceDate) {
		return Todo.builder()
				.userId(master.getUserId())
				.categoryId(master.getCategoryId())
				.title(master.getTitle())
				.content(master.getContent())
				.type(TodoType.NORMAL)
				.status(TodoStatus.TODO)
				.priority(master.getPriority())
				.alertTime(master.getAlertTime())
				.startDate(occurrenceDate)
				.endDate(null)
				.masterTodoId(master.getTodoId())
				.daysOfWeekRaw(null)
				.isDeleted(false)
				.expGranted(false)
				.build();
	}

	private static String toRawDaysOfWeek(Set<DayOfWeek> daysOfWeek) {
		if (daysOfWeek == null || daysOfWeek.isEmpty()) {
			return null;
		}
		return daysOfWeek.stream()
				.sorted()
				.map(Todo::toDayOfWeekCode)
				.collect(Collectors.joining(","));
	}

	public static DayOfWeek toDayOfWeek(String code) {
		return switch (code.toUpperCase(Locale.ROOT)) {
			case "MON" -> DayOfWeek.MONDAY;
			case "TUE" -> DayOfWeek.TUESDAY;
			case "WED" -> DayOfWeek.WEDNESDAY;
			case "THU" -> DayOfWeek.THURSDAY;
			case "FRI" -> DayOfWeek.FRIDAY;
			case "SAT" -> DayOfWeek.SATURDAY;
			case "SUN" -> DayOfWeek.SUNDAY;
			default -> throw new IllegalArgumentException("Unknown dayOfWeek: " + code);
		};
	}

	public static String toDayOfWeekCode(DayOfWeek dayOfWeek) {
		return switch (dayOfWeek) {
			case MONDAY -> "MON";
			case TUESDAY -> "TUE";
			case WEDNESDAY -> "WED";
			case THURSDAY -> "THU";
			case FRIDAY -> "FRI";
			case SATURDAY -> "SAT";
			case SUNDAY -> "SUN";
		};
	}
}
