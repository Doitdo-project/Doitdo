package com.doitdo.domain.todo.repository;

import com.doitdo.domain.todo.entity.Todo;
import com.doitdo.domain.todo.entity.Todo.TodoStatus;
import com.doitdo.domain.todo.entity.Todo.TodoType;
import jakarta.persistence.criteria.Predicate;
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
					cb.and(
							cb.isNotNull(root.get("startDate")),
							cb.equal(root.get("startDate"), baseDate)
					),
					cb.and(
							cb.equal(root.get("type"), TodoType.PERIOD),
							cb.isNotNull(root.get("startDate")),
							cb.lessThanOrEqualTo(root.get("startDate"), baseDate),
							cb.greaterThanOrEqualTo(root.get("endDate"), baseDate)
					)
			);
			case "upcoming" -> (root, query, cb) -> cb.and(
					cb.isNotNull(root.get("startDate")),
					cb.greaterThan(root.get("startDate"), baseDate)
			);
			case "past" -> (root, query, cb) -> cb.or(
					cb.and(
							cb.isNotNull(root.get("startDate")),
							cb.lessThan(root.get("endDate"), baseDate)
					),
					cb.and(
							cb.isNotNull(root.get("startDate")),
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

	/**
	 * 카테고리 이름 스냅샷 기반 필터. null/blank 이면 no-op.
	 * 카테고리 삭제 후에도 todo 에 남은 categoryName 스냅샷과 매칭되며,
	 * 동일 이름의 카테고리를 다시 만들면 옛 todo 들도 자연스럽게 잡힌다 (의도된 동작).
	 */
	public static Specification<Todo> byCategoryName(String categoryName) {
		if (categoryName == null || categoryName.isBlank()) {
			return (root, query, cb) -> cb.conjunction();
		}
		return (root, query, cb) -> cb.equal(root.get("categoryName"), categoryName);
	}

	/** type 필터: null 이면 no-op */
	public static Specification<Todo> byType(TodoType type) {
		if (type == null) {
			return (root, query, cb) -> cb.conjunction();
		}
		return (root, query, cb) -> cb.equal(root.get("type"), type);
	}

	/**
	 * SOMEDAY DONE 의 노출 만료 처리.
	 * NOT (type=SOMEDAY AND status=DONE AND done_date < today).
	 * done_date=NULL 인 기존 데이터는 통과한다.
	 */
	public static Specification<Todo> excludeExpiredSomedayDone(LocalDate today) {
		return (root, query, cb) -> cb.not(
				cb.and(
						cb.equal(root.get("type"), TodoType.SOMEDAY),
						cb.equal(root.get("status"), TodoStatus.DONE),
						cb.isNotNull(root.get("doneDate")),
						cb.lessThan(root.get("doneDate"), today)
				)
		);
	}

	/**
	 * 캘린더 범위 매칭. type 별 의미가 다르다.
	 * - NORMAL: 단일 날짜 todo. {@code from <= startDate <= to} 만 매칭 (endDate 는 의미 없음).
	 * - PERIOD: 기간형 todo. 기간이 [from, to] 와 겹치면 매칭.
	 * - RECURRING: 마스터 row. startDate <= to 인 마스터는 가상 occurrence 펼치기 위해 모두 잡아야 함 (endDate=null 무한 반복 포함).
	 */
	public static Specification<Todo> overlappingRange(LocalDate from, LocalDate to) {
		return (root, query, cb) -> {
			Predicate normalInRange = cb.and(
					cb.equal(root.get("type"), TodoType.NORMAL),
					cb.isNotNull(root.get("startDate")),
					cb.greaterThanOrEqualTo(root.get("startDate"), from),
					cb.lessThanOrEqualTo(root.get("startDate"), to)
			);
			Predicate nonNormalOverlap = cb.and(
					cb.notEqual(root.get("type"), TodoType.NORMAL),
					cb.isNotNull(root.get("startDate")),
					cb.lessThanOrEqualTo(root.get("startDate"), to),
					cb.or(
							cb.isNull(root.get("endDate")),
							cb.greaterThanOrEqualTo(root.get("endDate"), from)
					)
			);
			return cb.or(normalInRange, nonNormalOverlap);
		};
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
