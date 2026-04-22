package com.doitdo.domain.todo.application.impl;

import com.doitdo.domain.todo.api.dto.req.TodoCalendarReq;
import com.doitdo.domain.todo.api.dto.req.TodoSnoozeReq;
import com.doitdo.domain.todo.api.dto.resp.CalendarItemResp;
import com.doitdo.domain.todo.api.dto.resp.TodoCalendarResp;
import com.doitdo.domain.todo.application.RecurrenceService;
import com.doitdo.domain.todo.entity.Category;
import com.doitdo.domain.todo.entity.Todo;
import com.doitdo.domain.todo.entity.Todo.TodoType;
import com.doitdo.domain.todo.repository.CategoryRepository;
import com.doitdo.domain.todo.repository.SnoozeHistoryRepository;
import com.doitdo.domain.todo.repository.SnoozeHistoryRepository.SnoozeCountProjection;
import com.doitdo.domain.todo.repository.SnoozeHistoryRepository.SnoozeOriginProjection;
import com.doitdo.domain.todo.repository.TodoRepository;
import com.doitdo.domain.todo.repository.TodoSpecifications;
import com.doitdo.global.exception.CustomException;
import com.doitdo.global.exception.TodoErrorCode;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Sort;
import org.springframework.data.domain.Sort.Order;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

@Service
@RequiredArgsConstructor
public class RecurrenceServiceImpl implements RecurrenceService {

	private final TodoRepository todoRepository;
	private final CategoryRepository categoryRepository;
	private final SnoozeHistoryRepository snoozeHistoryRepository;

	@Override
	@Transactional(readOnly = true)
	public TodoCalendarResp calendar(Long userId, TodoCalendarReq req) {
		validateCalendarRange(req);

		Long categoryId = resolveCategoryId(userId, req.category());
		if (StringUtils.hasText(req.category()) && categoryId == null) {
			return new TodoCalendarResp(List.of());
		}

		Specification<Todo> baseSpec = TodoSpecifications.ownerAndActive(userId)
				.and(TodoSpecifications.overlappingRange(req.from(), req.to()))
				.and(TodoSpecifications.byCategoryId(categoryId));

		List<Todo> overlappingTodos = todoRepository.findAll(
				baseSpec,
				Sort.by(Order.asc("startDate"), Order.asc("todoId"))
		);

		List<Todo> recurringMasters = overlappingTodos.stream()
				.filter(todo -> todo.getType() == TodoType.RECURRING)
				.toList();
		List<Todo> actualTodos = overlappingTodos.stream()
				.filter(todo -> todo.getType() != TodoType.RECURRING)
				.toList();

		Map<Long, String> categoryNameById = buildCategoryNameMap(overlappingTodos);
		Map<Long, Integer> snoozeCountByTodoId = buildSnoozeCountMap(actualTodos);
		Map<Long, LocalDate> originalOccurrenceByTodoId = buildOriginalOccurrenceMap(actualTodos);
		Map<String, List<Todo>> mastersByTitle = recurringMasters.stream()
				.collect(Collectors.groupingBy(Todo::getTitle));

		Map<Long, Set<LocalDate>> actualizedOccurrencesByMasterId = new HashMap<>();
		List<CalendarItemResp> items = new ArrayList<>();

		for (Todo actualTodo : actualTodos) {
			LocalDate originalOccurrenceDate = originalOccurrenceByTodoId.getOrDefault(actualTodo.getTodoId(), actualTodo.getStartDate());
			Todo matchedMaster = findMatchingRecurringMaster(actualTodo, originalOccurrenceDate, mastersByTitle);
			if (matchedMaster != null) {
				actualizedOccurrencesByMasterId
						.computeIfAbsent(matchedMaster.getTodoId(), ignored -> new java.util.HashSet<>())
						.add(originalOccurrenceDate);
				actualizedOccurrencesByMasterId.get(matchedMaster.getTodoId()).add(actualTodo.getStartDate());
			}

			CalendarItemResp item = toActualCalendarItem(
					actualTodo,
					matchedMaster,
					actualTodo.getCategoryId() != null ? categoryNameById.get(actualTodo.getCategoryId()) : null,
					snoozeCountByTodoId.getOrDefault(actualTodo.getTodoId(), 0)
			);
			if (matchesCalendarFilters(item, req)) {
				items.add(item);
			}
		}

		for (Todo master : recurringMasters) {
			Set<LocalDate> actualizedDates = actualizedOccurrencesByMasterId.getOrDefault(master.getTodoId(), Set.of());
			for (LocalDate occurrenceDate : CalendarOccurrenceGenerator.generate(master, req.from(), req.to())) {
				if (actualizedDates.contains(occurrenceDate)) {
					continue;
				}

				CalendarItemResp item = CalendarItemResp.fromVirtual(
						master,
						master.getCategoryId() != null ? categoryNameById.get(master.getCategoryId()) : null,
						occurrenceDate
				);
				if (matchesCalendarFilters(item, req)) {
					items.add(item);
				}
			}
		}

		items.sort(Comparator
				.comparing(this::calendarSortDate)
				.thenComparing(item -> item.todoId() == null ? Long.MAX_VALUE : item.todoId()));

		return new TodoCalendarResp(items);
	}

	@Override
	public Todo materializeRecurringIfNeeded(Long userId, Todo todo, TodoSnoozeReq req) {
		if (todo.getType() != TodoType.RECURRING) {
			return todo;
		}
		return materializeRecurringInstance(userId, todo, req);
	}

	private void validateCalendarRange(TodoCalendarReq req) {
		if (req.from() == null || req.to() == null || req.from().isAfter(req.to())) {
			throw new CustomException(TodoErrorCode.T08_002);
		}
	}

	private Long resolveCategoryId(Long userId, String categoryName) {
		if (!StringUtils.hasText(categoryName)) {
			return null;
		}
		return categoryRepository.findByCategoryNameAndUserId(categoryName, userId)
				.map(Category::getCategoryId)
				.orElse(null);
	}

	private Map<Long, String> buildCategoryNameMap(List<Todo> todos) {
		Set<Long> categoryIds = todos.stream()
				.map(Todo::getCategoryId)
				.filter(id -> id != null)
				.collect(Collectors.toSet());

		return categoryIds.isEmpty()
				? Map.of()
				: categoryRepository.findAllById(categoryIds).stream()
						.collect(Collectors.toMap(Category::getCategoryId, Category::getCategoryName));
	}

	private Map<Long, Integer> buildSnoozeCountMap(List<Todo> todos) {
		Set<Long> todoIds = todos.stream()
				.map(Todo::getTodoId)
				.collect(Collectors.toSet());

		return todoIds.isEmpty()
				? Map.of()
				: snoozeHistoryRepository.countByTodoIdIn(todoIds).stream()
						.collect(Collectors.toMap(
								SnoozeCountProjection::getTodoId,
								projection -> projection.getCnt().intValue()
						));
	}

	private Map<Long, LocalDate> buildOriginalOccurrenceMap(List<Todo> todos) {
		Set<Long> todoIds = todos.stream()
				.map(Todo::getTodoId)
				.collect(Collectors.toSet());

		return todoIds.isEmpty()
				? Map.of()
				: snoozeHistoryRepository.findEarliestFromDateByTodoIdIn(todoIds).stream()
						.collect(Collectors.toMap(
								SnoozeOriginProjection::getTodoId,
								SnoozeOriginProjection::getFromDate
						));
	}

	private CalendarItemResp toActualCalendarItem(Todo actualTodo, Todo matchedMaster, String categoryName, int snoozedDays) {
		TodoType responseType = matchedMaster != null ? TodoType.RECURRING : actualTodo.getType();
		Integer responsePeriod = matchedMaster != null ? matchedMaster.getPeriod() : actualTodo.getPeriod();
		Long masterTodoId = matchedMaster != null ? matchedMaster.getTodoId() : null;
		return CalendarItemResp.fromActual(actualTodo, masterTodoId, categoryName, responseType, responsePeriod, snoozedDays);
	}

	private Todo findMatchingRecurringMaster(
			Todo actualTodo,
			LocalDate originalOccurrenceDate,
			Map<String, List<Todo>> mastersByTitle) {
		if (actualTodo.getType() != TodoType.NORMAL) {
			return null;
		}

		return mastersByTitle.getOrDefault(actualTodo.getTitle(), List.of()).stream()
				.filter(master -> isOccurrenceOfMaster(master, originalOccurrenceDate))
				.findFirst()
				.orElse(null);
	}

	private boolean isOccurrenceOfMaster(Todo master, LocalDate occurrenceDate) {
		if (master.getPeriod() == null || master.getPeriod() <= 0) {
			return false;
		}
		if (occurrenceDate.isBefore(master.getStartDate())) {
			return false;
		}
		if (master.getEndDate() != null && occurrenceDate.isAfter(master.getEndDate())) {
			return false;
		}

		long diff = java.time.temporal.ChronoUnit.DAYS.between(master.getStartDate(), occurrenceDate);
		return diff % master.getPeriod() == 0;
	}

	private boolean matchesCalendarFilters(CalendarItemResp item, TodoCalendarReq req) {
		if (req.status() != null && item.status() != req.status()) {
			return false;
		}
		if (req.type() != null && item.type() != req.type()) {
			return false;
		}
		return true;
	}

	private LocalDate calendarSortDate(CalendarItemResp item) {
		return item.occurrenceDate() != null ? item.occurrenceDate() : item.startDate();
	}

	private Todo materializeRecurringInstance(Long userId, Todo master, TodoSnoozeReq req) {
		LocalDate occurrenceDate = req != null ? req.occurrenceDate() : null;
		if (occurrenceDate == null || !isOccurrenceOfMaster(master, occurrenceDate)) {
			throw new CustomException(TodoErrorCode.T05_004);
		}

		return todoRepository.findByUserIdAndTitleAndStartDateAndTypeAndIsDeletedFalse(
						userId,
						master.getTitle(),
						occurrenceDate,
						TodoType.NORMAL)
				.orElseGet(() -> findExistingMaterializedInstance(userId, master.getTitle(), occurrenceDate)
						.orElseGet(() -> todoRepository.save(Todo.createRecurringInstance(master, occurrenceDate))));
	}

	private Optional<Todo> findExistingMaterializedInstance(Long userId, String title, LocalDate occurrenceDate) {
		List<Todo> candidates = todoRepository.findAllByUserIdAndTitleAndTypeAndIsDeletedFalse(userId, title, TodoType.NORMAL);
		if (candidates.isEmpty()) {
			return Optional.empty();
		}

		Map<Long, LocalDate> originalOccurrenceByTodoId = buildOriginalOccurrenceMap(candidates);
		return candidates.stream()
				.filter(todo -> occurrenceDate.equals(originalOccurrenceByTodoId.get(todo.getTodoId())))
				.findFirst();
	}
}
