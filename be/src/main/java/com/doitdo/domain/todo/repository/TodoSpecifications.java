package com.doitdo.domain.todo.repository;

import com.doitdo.domain.todo.entity.Todo;
import com.doitdo.domain.todo.entity.Todo.TodoStatus;
import com.doitdo.domain.todo.entity.Todo.TodoType;
import java.time.LocalDate;
import org.springframework.data.jpa.domain.Specification;

public final class TodoSpecifications {

	private TodoSpecifications() {}

	/** 기본 조건: 소유자 + 삭제되지 않음 */
	public static Specification<Todo> ownerAndActive(Long userId) {
		return (root, query, cb) -> cb.and(
				cb.equal(root.get("userId"), userId),
				cb.isFalse(root.get("isDeleted"))
		);
	}

	/**
	 * view 필터
	 * - today: startDate == baseDate OR (type==PERIOD AND startDate <= baseDate AND endDate >= baseDate)
	 * - upcoming: startDate > baseDate
	 * - past: endDate < baseDate OR (endDate IS NULL AND startDate < baseDate)
	 * - all 또는 null: no-op
	 */
	public static Specification<Todo> byView(String view, LocalDate baseDate) {
		if (view == null || "all".equalsIgnoreCase(view)) {
			return (root, query, cb) -> cb.conjunction();
		}

		return switch (view.toLowerCase()) {
			case "today" -> (root, query, cb) -> cb.or(
					cb.equal(root.get("startDate"), baseDate),
					cb.and(
							cb.equal(root.get("type"), TodoType.PERIOD),
							cb.lessThanOrEqualTo(root.get("startDate"), baseDate),
							cb.greaterThanOrEqualTo(root.get("endDate"), baseDate)
					)
			);
			case "upcoming" -> (root, query, cb) -> cb.greaterThan(root.get("startDate"), baseDate);
			case "past" -> (root, query, cb) -> cb.or(
					cb.lessThan(root.get("endDate"), baseDate),
					cb.and(
							cb.isNull(root.get("endDate")),
							cb.lessThan(root.get("startDate"), baseDate)
					)
			);
			default -> (root, query, cb) -> cb.conjunction();
		};
	}

	/** status 필터: null 이면 no-op */
	public static Specification<Todo> byStatus(TodoStatus status) {
		if (status == null) {
			return (root, query, cb) -> cb.conjunction();
		}
		return (root, query, cb) -> cb.equal(root.get("status"), status);
	}

	/** categoryId 필터: null 이면 no-op */
	public static Specification<Todo> byCategoryId(Long categoryId) {
		if (categoryId == null) {
			return (root, query, cb) -> cb.conjunction();
		}
		return (root, query, cb) -> cb.equal(root.get("categoryId"), categoryId);
	}

	/** type 필터: null 이면 no-op */
	public static Specification<Todo> byType(TodoType type) {
		if (type == null) {
			return (root, query, cb) -> cb.conjunction();
		}
		return (root, query, cb) -> cb.equal(root.get("type"), type);
	}

	/** 키워드 검색: title LIKE %q% OR content LIKE %q%. null/blank 이면 no-op */
	public static Specification<Todo> byKeyword(String q) {
		if (q == null || q.isBlank()) {
			return (root, query, cb) -> cb.conjunction();
		}
		final String pattern = "%" + q + "%";
		return (root, query, cb) -> cb.or(
				cb.like(root.get("title"), pattern),
				cb.like(root.get("content"), pattern)
		);
	}
}
