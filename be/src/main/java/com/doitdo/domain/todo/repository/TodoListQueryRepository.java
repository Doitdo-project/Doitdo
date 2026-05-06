package com.doitdo.domain.todo.repository;

import com.doitdo.domain.todo.entity.Todo.TodoStatus;
import com.doitdo.domain.todo.entity.Todo.TodoType;
import com.doitdo.domain.todo.repository.projection.TodoListRow;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.persistence.TypedQuery;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import org.springframework.stereotype.Repository;
import org.springframework.util.StringUtils;

@Repository
public class TodoListQueryRepository {

	private static final String SELECT_CLAUSE = """
			SELECT new com.doitdo.domain.todo.repository.projection.TodoListRow(
				t.todoId,
				t.title,
				t.content,
				c.categoryName,
				t.type,
				t.priority,
				t.alertTime,
				t.startDate,
				t.endDate,
				t.daysOfWeekRaw,
				t.status,
				t.updatedAt,
				COUNT(sh.snoozeHistoryId)
			)
			""";

	private static final String GROUP_BY_CLAUSE = """
			GROUP BY
				t.todoId,
				t.title,
				t.content,
				c.categoryName,
				t.type,
				t.priority,
				t.alertTime,
				t.startDate,
				t.endDate,
				t.daysOfWeekRaw,
				t.status,
				t.updatedAt
			""";

	@PersistenceContext
	private EntityManager entityManager;

	public List<TodoListRow> findListRows(
			Long userId,
			String view,
			TodoStatus status,
			String categoryName,
			TodoType type,
			LocalDate baseDate,
			LocalDate today,
			String keyword,
			String sort) {

		Map<String, Object> params = new HashMap<>();
		params.put("userId", userId);
		params.put("today", today);

		StringBuilder jpql = new StringBuilder(SELECT_CLAUSE)
				.append("FROM Todo t\n");
		appendCategoryJoin(jpql, params, categoryName);
		jpql.append("LEFT JOIN SnoozeHistory sh ON sh.todoId = t.todoId\n");

		List<String> where = new ArrayList<>();
		where.add("t.userId = :userId");
		where.add("t.isDeleted = false");
		where.add("""
				NOT (
					t.type = com.doitdo.domain.todo.entity.Todo.TodoType.SOMEDAY
					AND t.status = com.doitdo.domain.todo.entity.Todo.TodoStatus.DONE
					AND t.doneDate IS NOT NULL
					AND t.doneDate < :today
				)
				""");

		appendViewFilter(where, params, view, baseDate);
		appendStatusFilter(where, params, status);
		appendTypeFilter(where, params, type);
		appendKeywordFilter(where, params, keyword);

		jpql.append("WHERE ")
				.append(String.join("\nAND ", where))
				.append("\n")
				.append(GROUP_BY_CLAUSE)
				.append(resolveOrderBy(sort));

		TypedQuery<TodoListRow> query = entityManager.createQuery(jpql.toString(), TodoListRow.class);
		params.forEach(query::setParameter);
		return query.getResultList();
	}

	private void appendCategoryJoin(StringBuilder jpql, Map<String, Object> params, String categoryName) {
		if (StringUtils.hasText(categoryName)) {
			jpql.append("""
					JOIN Category c ON c.categoryId = t.categoryId
						AND c.userId = :userId
						AND c.categoryName = :categoryName
					""");
			params.put("categoryName", categoryName);
			return;
		}

		jpql.append("LEFT JOIN Category c ON c.categoryId = t.categoryId\n");
	}

	private void appendViewFilter(
			List<String> where,
			Map<String, Object> params,
			String view,
			LocalDate baseDate) {
		String normalizedView = normalize(view);
		if (normalizedView == null || "all".equals(normalizedView)) {
			return;
		}

		switch (normalizedView) {
			case "today" -> {
				where.add("""
						(
							(t.startDate IS NOT NULL AND t.startDate = :baseDate)
							OR (
								t.type = com.doitdo.domain.todo.entity.Todo.TodoType.PERIOD
								AND t.startDate IS NOT NULL
								AND t.startDate <= :baseDate
								AND t.endDate >= :baseDate
							)
						)
						""");
				params.put("baseDate", baseDate);
			}
			case "upcoming" -> {
				where.add("t.startDate IS NOT NULL AND t.startDate > :baseDate");
				params.put("baseDate", baseDate);
			}
			case "past" -> {
				where.add("""
						(
							(t.startDate IS NOT NULL AND t.endDate < :baseDate)
							OR (
								t.startDate IS NOT NULL
								AND t.endDate IS NULL
								AND t.startDate < :baseDate
							)
						)
						""");
				params.put("baseDate", baseDate);
			}
			default -> {
				// Unknown view values keep the previous Specification behavior: no-op.
			}
		}
	}

	private void appendStatusFilter(List<String> where, Map<String, Object> params, TodoStatus status) {
		if (status == null) {
			return;
		}
		where.add("t.status = :status");
		params.put("status", status);
	}

	private void appendTypeFilter(List<String> where, Map<String, Object> params, TodoType type) {
		if (type == null) {
			return;
		}
		where.add("t.type = :type");
		params.put("type", type);
	}

	private void appendKeywordFilter(List<String> where, Map<String, Object> params, String keyword) {
		if (!StringUtils.hasText(keyword)) {
			return;
		}
		where.add("(t.title LIKE :keyword OR t.content LIKE :keyword)");
		params.put("keyword", "%" + keyword + "%");
	}

	private String resolveOrderBy(String sort) {
		String normalizedSort = normalize(sort);
		if ("category".equals(normalizedSort)) {
			return "\nORDER BY t.categoryId ASC, t.startDate ASC, t.todoId ASC";
		}
		if ("priority".equals(normalizedSort)) {
			return "\nORDER BY t.priority DESC, t.startDate ASC, t.todoId ASC";
		}
		return "\nORDER BY t.startDate ASC, t.todoId ASC";
	}

	private String normalize(String value) {
		if (!StringUtils.hasText(value)) {
			return null;
		}
		return value.toLowerCase(Locale.ROOT);
	}
}
