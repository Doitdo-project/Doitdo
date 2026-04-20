package com.doitdo.domain.todo.entity;

import java.time.LocalDate;

import com.doitdo.global.entity.BaseTimeEntity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
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

	public enum TodoType { NORMAL, RECURRING, PERIOD }

	public enum TodoStatus { TODO, IN_PROGRESS, DONE }

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	@Column(name = "tool_id")
	private Long toolId;

	@Column(name = "user_id", nullable = false)
	private Long userId;

	@Column(name = "category_id")
	private Long categoryId;

	@Column(nullable = false, length = 255)
	private String title;

	@Column(columnDefinition = "TEXT")
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

	@Column(name = "start_date", nullable = false)
	private LocalDate startDate;

	@Column(name = "end_date")
	private LocalDate endDate;

	private Integer period;

	@Column(name = "is_deleted", nullable = false)
	private Boolean isDeleted;
}
