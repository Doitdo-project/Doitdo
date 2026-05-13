package com.doitdo.domain.todo.entity;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.ZoneId;
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
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import jakarta.persistence.Transient;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Getter
@Table(
		name = "todos",
		indexes = {
				@Index(name = "idx_todos_list_default", columnList = "user_id, is_deleted, start_date, todo_id"),
				@Index(name = "idx_todos_list_type", columnList = "user_id, is_deleted, type, start_date, todo_id"),
				@Index(name = "idx_todos_list_status", columnList = "user_id, is_deleted, status, start_date, todo_id"),
				@Index(name = "idx_todos_list_category", columnList = "user_id, is_deleted, category_id, start_date, todo_id"),
				@Index(name = "idx_todos_list_category_name", columnList = "user_id, is_deleted, category_name, start_date, todo_id"),
				@Index(name = "idx_todos_list_priority", columnList = "user_id, is_deleted, priority, start_date, todo_id")
		}
)
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

	/**
	 * 카테고리 이름 스냅샷. 카테고리 rename 시 일괄 update 로 전파되며,
	 * 카테고리 삭제 시에도 그대로 남아 todo 가 "삭제된 카테고리" 를 표현한다.
	 */
	@Column(name = "category_name", length = 10)
	private String categoryName;

	/**
	 * 카테고리 색상 스냅샷 (PaletteColor.colorId). 응답 단계에서 동일 이름의
	 * 활성 카테고리가 있으면 그 색이 override 하고, 없으면 이 값으로 hex 를 해석한다.
	 */
	@Column(name = "category_color_id")
	private Integer categoryColorId;

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

	@Column(name = "done_date")
	private LocalDate doneDate;

	@Column(name = "first_completed_date", nullable = true)
	private LocalDate firstCompletedDate;

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

	public void changeStatus(TodoStatus next) {
		if (next == TodoStatus.DONE && this.status != TodoStatus.DONE) {
			this.doneDate = LocalDate.now(ZoneId.of("Asia/Seoul"));
		}
		if (next != TodoStatus.DONE && this.status == TodoStatus.DONE) {
			this.doneDate = null;
		}
		this.status = next;
	}

	/** 경험치 지급 완료 마킹. 멱등 (이미 true 면 no-op). */
	public void markExpGranted() {
		this.expGranted = true;
	}

	/** 최초 완료일 마킹. 멱등 (이미 값이 있으면 no-op). */
	public void markFirstCompletedIfAbsent(LocalDate today) {
		if (this.firstCompletedDate == null) {
			this.firstCompletedDate = today;
		}
	}

	public void changePriority(Integer priority) {
		this.priority = priority;
	}

	public void changeEndDate(LocalDate endDate) {
		this.endDate = endDate;
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
			String categoryName,
			Integer categoryColorId,
			TodoType type,
			LocalDate startDate,
			LocalDate endDate,
			Set<DayOfWeek> daysOfWeek,
			String alertTime) {
		if (title != null) this.title = title;
		this.content = content;
		if (categoryId != null) {
			this.categoryId = categoryId;
			this.categoryName = categoryName;
			this.categoryColorId = categoryColorId;
		}
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
			String categoryName,
			Integer categoryColorId,
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
				.categoryName(categoryName)
				.categoryColorId(categoryColorId)
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
				.categoryName(master.getCategoryName())
				.categoryColorId(master.getCategoryColorId())
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
