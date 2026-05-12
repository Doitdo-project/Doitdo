package com.doitdo.domain.todo.application.impl;

import com.doitdo.domain.todo.api.dto.req.TodoCalendarReq;
import com.doitdo.domain.todo.api.dto.req.TodoSnoozeReq;
import com.doitdo.domain.todo.api.dto.resp.CalendarItemResp;
import com.doitdo.domain.todo.api.dto.resp.TodoCalendarResp;
import com.doitdo.domain.todo.application.RecurrenceService;
import com.doitdo.domain.todo.entity.Category;
import com.doitdo.domain.todo.entity.PaletteColor;
import com.doitdo.domain.todo.entity.Todo;
import com.doitdo.domain.todo.entity.Todo.TodoType;
import com.doitdo.domain.todo.repository.CategoryRepository;
import com.doitdo.domain.todo.repository.PaletteColorRepository;
import com.doitdo.domain.todo.repository.SnoozeHistoryRepository;
import com.doitdo.domain.todo.repository.SnoozeHistoryRepository.SnoozeCountProjection;
import com.doitdo.domain.todo.repository.SnoozeHistoryRepository.SnoozeOriginProjection;
import com.doitdo.domain.todo.repository.TodoRepository;
import com.doitdo.domain.todo.repository.TodoSpecifications;
import com.doitdo.global.exception.CustomException;
import com.doitdo.global.exception.ErrorCode;
import com.doitdo.global.exception.TodoErrorCode;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.function.Function;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.data.domain.Sort;
import org.springframework.data.domain.Sort.Order;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Slf4j
@Service
@RequiredArgsConstructor
public class RecurrenceServiceImpl implements RecurrenceService {

	private final TodoRepository todoRepository;
	private final CategoryRepository categoryRepository;
	private final PaletteColorRepository paletteColorRepository;
	private final SnoozeHistoryRepository snoozeHistoryRepository;

	@Override
	@Transactional(readOnly = true)
	public TodoCalendarResp calendar(Long userId, TodoCalendarReq req) {
		validateCalendarRange(req);

		Specification<Todo> baseSpec = TodoSpecifications.ownerAndActive(userId)
				.and(TodoSpecifications.overlappingRange(req.from(), req.to()))
				.and(TodoSpecifications.byCategoryName(req.category()));

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

		Map<String, Integer> activeColorByName = buildActiveCategoryColorIdByName(userId);
		Map<Integer, String> hexByColorId = buildPaletteHexByColorId();
		Map<Long, Integer> snoozeCountByTodoId = buildSnoozeCountMap(actualTodos);
		Map<Long, LocalDate> originalOccurrenceByTodoId = buildOriginalOccurrenceMap(actualTodos);
		Map<Long, Todo> mastersById = recurringMasters.stream()
				.collect(Collectors.toMap(Todo::getTodoId, Function.identity()));
		Map<String, List<Todo>> mastersByTitle = recurringMasters.stream()
				.collect(Collectors.groupingBy(Todo::getTitle));

		Map<Long, Set<LocalDate>> actualizedOccurrencesByMasterId = new HashMap<>();
		List<CalendarItemResp> items = new ArrayList<>();

		for (Todo actualTodo : actualTodos) {
			LocalDate originalOccurrenceDate = originalOccurrenceByTodoId.getOrDefault(actualTodo.getTodoId(), actualTodo.getStartDate());
			Todo matchedMaster = findMatchingRecurringMaster(actualTodo, originalOccurrenceDate, mastersById, mastersByTitle);
			if (matchedMaster != null) {
				actualizedOccurrencesByMasterId
						.computeIfAbsent(matchedMaster.getTodoId(), ignored -> new java.util.HashSet<>())
						.add(originalOccurrenceDate);
				actualizedOccurrencesByMasterId.get(matchedMaster.getTodoId()).add(actualTodo.getStartDate());
			}

			String colorHex = resolveColorHex(actualTodo.getCategoryName(), actualTodo.getCategoryColorId(),
					activeColorByName, hexByColorId);
			CalendarItemResp item = toActualCalendarItem(
					actualTodo,
					matchedMaster,
					actualTodo.getCategoryName(),
					colorHex,
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

				String colorHex = resolveColorHex(master.getCategoryName(), master.getCategoryColorId(),
						activeColorByName, hexByColorId);
				CalendarItemResp item = CalendarItemResp.fromVirtual(
						master,
						master.getCategoryName(),
						colorHex,
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
		LocalDate occurrenceDate = req != null ? req.occurrenceDate() : null;
		return materializeRecurringOccurrence(userId, todo, occurrenceDate, TodoErrorCode.T05_004);
	}

	@Override
	public Todo materializeRecurringOccurrence(Long userId, Todo master, LocalDate occurrenceDate) {
		return materializeRecurringOccurrence(userId, master, occurrenceDate, TodoErrorCode.T03_004);
	}

	private Todo materializeRecurringOccurrence(
			Long userId,
			Todo master,
			LocalDate occurrenceDate,
			ErrorCode invalidOccurrenceErrorCode) {
		if (occurrenceDate == null || !isOccurrenceOfMaster(master, occurrenceDate)) {
			throw new CustomException(invalidOccurrenceErrorCode);
		}

		return todoRepository.findByUserIdAndMasterTodoIdAndStartDateAndIsDeletedFalse(
						userId,
						master.getTodoId(),
						occurrenceDate)
				.orElseGet(() -> saveRecurringInstanceIdempotently(master, occurrenceDate));
	}

	private void validateCalendarRange(TodoCalendarReq req) {
		if (req.from() == null || req.to() == null || req.from().isAfter(req.to())) {
			throw new CustomException(TodoErrorCode.T08_002);
		}
	}

	private Map<String, Integer> buildActiveCategoryColorIdByName(Long userId) {
		return categoryRepository.findAllByUserIdOrderByCategoryIdAsc(userId).stream()
				.collect(Collectors.toMap(Category::getCategoryName, Category::getColorId, (a, b) -> a));
	}

	private Map<Integer, String> buildPaletteHexByColorId() {
		return paletteColorRepository.findAll().stream()
				.collect(Collectors.toMap(PaletteColor::getColorId, PaletteColor::getColor));
	}

	private static String resolveColorHex(
			String categoryName,
			Integer snapshotColorId,
			Map<String, Integer> activeColorIdByName,
			Map<Integer, String> hexByColorId) {
		if (categoryName == null) {
			return null;
		}
		Integer colorId = activeColorIdByName.get(categoryName);
		if (colorId == null) {
			colorId = snapshotColorId;
		}
		if (colorId == null) {
			return null;
		}
		return hexByColorId.get(colorId);
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

	private CalendarItemResp toActualCalendarItem(
			Todo actualTodo,
			Todo matchedMaster,
			String categoryName,
			String colorHex,
			int snoozedDays) {
		TodoType responseType = matchedMaster != null ? TodoType.RECURRING : actualTodo.getType();
		Set<DayOfWeek> responseDaysOfWeek = matchedMaster != null ? matchedMaster.getDaysOfWeek() : actualTodo.getDaysOfWeek();
		Long masterTodoId = matchedMaster != null ? matchedMaster.getTodoId() : null;
		return CalendarItemResp.fromActual(actualTodo, masterTodoId, categoryName, colorHex, responseType, responseDaysOfWeek, snoozedDays);
	}

	private Todo findMatchingRecurringMaster(
			Todo actualTodo,
			LocalDate originalOccurrenceDate,
			Map<Long, Todo> mastersById,
			Map<String, List<Todo>> mastersByTitle) {
		if (actualTodo.getType() != TodoType.NORMAL) {
			return null;
		}

		if (actualTodo.getMasterTodoId() != null) {
			Todo master = mastersById.get(actualTodo.getMasterTodoId());
			return master != null && isOccurrenceOfMaster(master, originalOccurrenceDate) ? master : null;
		}

		return mastersByTitle.getOrDefault(actualTodo.getTitle(), List.of()).stream()
				.filter(master -> isOccurrenceOfMaster(master, originalOccurrenceDate))
				.findFirst()
				.orElse(null);
	}

	private boolean isOccurrenceOfMaster(Todo master, LocalDate occurrenceDate) {
		Set<DayOfWeek> daysOfWeek = master.getDaysOfWeek();
		if (daysOfWeek.isEmpty()) {
			return false;
		}
		if (occurrenceDate.isBefore(master.getStartDate())) {
			return false;
		}
		if (master.getEndDate() != null && occurrenceDate.isAfter(master.getEndDate())) {
			return false;
		}

		return daysOfWeek.contains(occurrenceDate.getDayOfWeek());
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

	private Todo saveRecurringInstanceIdempotently(Todo master, LocalDate occurrenceDate) {
		try {
			return todoRepository.saveAndFlush(Todo.createRecurringInstance(master, occurrenceDate));
		} catch (DataIntegrityViolationException ex) {
			log.warn("[recurrence] duplicate materialized instance skipped masterTodoId={} occurrenceDate={}",
					master.getTodoId(), occurrenceDate);
			return todoRepository.findByUserIdAndMasterTodoIdAndStartDateAndIsDeletedFalse(
							master.getUserId(),
							master.getTodoId(),
							occurrenceDate)
					.orElseThrow(() -> ex);
		}
	}
}
