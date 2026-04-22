package com.doitdo.domain.todo.application.impl;

import com.doitdo.domain.todo.api.dto.req.TodoCreateReq;
import com.doitdo.domain.todo.api.dto.req.TodoCalendarReq;
import com.doitdo.domain.todo.api.dto.req.TodoListReq;
import com.doitdo.domain.todo.api.dto.req.TodoPriorityChangeReq;
import com.doitdo.domain.todo.api.dto.req.TodoSearchReq;
import com.doitdo.domain.todo.api.dto.req.TodoSnoozeReq;
import com.doitdo.domain.todo.api.dto.req.TodoStatusChangeReq;
import com.doitdo.domain.todo.api.dto.req.TodoUpdateReq;
import com.doitdo.domain.todo.api.dto.resp.CalendarItemResp;
import com.doitdo.domain.todo.api.dto.resp.TodoCalendarResp;
import com.doitdo.domain.todo.api.dto.resp.TodoDetailResp;
import com.doitdo.domain.todo.api.dto.resp.TodoListResp;
import com.doitdo.domain.todo.api.dto.resp.TodoSearchResp;
import com.doitdo.domain.todo.application.TodoService;
import com.doitdo.domain.todo.entity.Category;
import com.doitdo.domain.todo.entity.SnoozeHistory;
import com.doitdo.domain.todo.entity.Todo;
import com.doitdo.domain.todo.entity.Todo.TodoStatus;
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
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.data.domain.Sort.Order;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

@Service
@RequiredArgsConstructor
public class TodoServiceImpl implements TodoService {

	private final TodoRepository todoRepository;
	private final CategoryRepository categoryRepository;
	private final SnoozeHistoryRepository snoozeHistoryRepository;
	private final CalendarOccurrenceGenerator calendarOccurrenceGenerator;

	@Override
	@Transactional(readOnly = true)
	public TodoListResp list(Long userId, TodoListReq req) {
		// 카테고리 이름 필터: 이름으로 Category 조회, 없으면 빈 결과 반환
		Long categoryId = null;
		if (StringUtils.hasText(req.category())) {
			Optional<Category> categoryOpt =
					categoryRepository.findByCategoryNameAndUserId(req.category(), userId);
			if (categoryOpt.isEmpty()) {
				return new TodoListResp(List.of());
			}
			categoryId = categoryOpt.get().getCategoryId();
		}

		// 기준일: date 파라미터가 있으면 그 날짜, 없으면 오늘
		LocalDate baseDate = req.date() != null ? req.date() : LocalDate.now();

		// Specification 조합
		Specification<Todo> spec = TodoSpecifications.ownerAndActive(userId)
				.and(TodoSpecifications.byView(req.view(), baseDate))
				.and(TodoSpecifications.byStatus(req.status()))
				.and(TodoSpecifications.byCategoryId(categoryId))
				.and(TodoSpecifications.byType(req.type()))
				.and(TodoSpecifications.byKeyword(req.q()));

		// Sort 결정
		Sort sort = resolveSort(req.sort());

		List<Todo> todos = todoRepository.findAll(spec, sort);

		// 카테고리 벌크 조회 (N+1 방지)
		Set<Long> categoryIds = todos.stream()
				.map(Todo::getCategoryId)
				.filter(id -> id != null)
				.collect(Collectors.toSet());

		Map<Long, String> categoryNameById = categoryIds.isEmpty()
				? Map.of()
				: categoryRepository.findAllById(categoryIds).stream()
						.collect(Collectors.toMap(Category::getCategoryId, Category::getCategoryName));

		// snooze 횟수 벌크 조회
		Set<Long> todoIds = todos.stream()
				.map(Todo::getTodoId)
				.collect(Collectors.toSet());

		Map<Long, Integer> snoozeCountByTodoId = todoIds.isEmpty()
				? Map.of()
				: snoozeHistoryRepository.countByTodoIdIn(todoIds).stream()
						.collect(Collectors.toMap(
								SnoozeCountProjection::getTodoId,
								p -> p.getCnt().intValue()
						));

		return TodoListResp.of(todos, categoryNameById, snoozeCountByTodoId);
	}

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
			}

			CalendarItemResp item = toActualCalendarItem(
					actualTodo,
					matchedMaster,
					categoryNameById.get(actualTodo.getCategoryId()),
					snoozeCountByTodoId.getOrDefault(actualTodo.getTodoId(), 0)
			);
			if (matchesCalendarFilters(item, req)) {
				items.add(item);
			}
		}

		for (Todo master : recurringMasters) {
			Set<LocalDate> actualizedDates = actualizedOccurrencesByMasterId.getOrDefault(master.getTodoId(), Set.of());
			for (LocalDate occurrenceDate : calendarOccurrenceGenerator.generate(master, req.from(), req.to())) {
				if (actualizedDates.contains(occurrenceDate)) {
					continue;
				}

				CalendarItemResp item = CalendarItemResp.fromVirtual(
						master,
						categoryNameById.get(master.getCategoryId()),
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

	private Sort resolveSort(String sortParam) {
		if (sortParam == null) {
			return Sort.by("startDate").ascending().and(Sort.by("todoId").ascending());
		}
		return switch (sortParam.toLowerCase()) {
			case "category" -> Sort.by("categoryId").ascending().and(Sort.by("startDate").ascending());
			case "priority" -> Sort.by("priority").descending().and(Sort.by("startDate").ascending());
			default -> Sort.by("startDate").ascending().and(Sort.by("todoId").ascending());
		};
	}

	@Override
	@Transactional(readOnly = true)
	public TodoDetailResp detail(Long userId, Long todoId) {
		Todo todo = todoRepository.findByTodoIdAndIsDeletedFalse(todoId)
				.orElseThrow(() -> new CustomException(TodoErrorCode.T00_001));

		if (!todo.getUserId().equals(userId)) {
			throw new CustomException(TodoErrorCode.T00_003);
		}

		String categoryName = null;
		if (todo.getCategoryId() != null) {
			categoryName = categoryRepository.findById(todo.getCategoryId())
					.map(Category::getCategoryName)
					.orElse(null);
		}

		int count = (int) snoozeHistoryRepository.countByTodoId(todo.getTodoId());
		return TodoDetailResp.from(todo, categoryName, count);
	}

	@Override
	@Transactional
	public TodoDetailResp create(Long userId, TodoCreateReq req) {
		if (req.type() == TodoType.RECURRING && req.period() == null) {
			throw new CustomException(TodoErrorCode.T06_002);
		}

		Long categoryId = null;
		String categoryName = null;
		if (StringUtils.hasText(req.category())) {
			Category category = categoryRepository.findByCategoryNameAndUserId(req.category(), userId)
					.orElseThrow(() -> new CustomException(TodoErrorCode.T06_003));
			categoryId = category.getCategoryId();
			categoryName = category.getCategoryName();
		}

		int priority = req.priority() != null ? req.priority() : 1;

		Todo todo = todoRepository.save(
				Todo.create(userId, categoryId, req.title(), req.content(),
						req.type(), priority, req.startDate(), req.endDate(), req.period())
		);

		// 새 TODO 이므로 snooze 이력 없음 — count=0 하드코딩 (DB 조회 불필요)
		return TodoDetailResp.from(todo, categoryName, 0);
	}

	@Override
	@Transactional
	public void delete(Long userId, Long todoId, String scope) {
		Todo todo = todoRepository.findByTodoIdAndIsDeletedFalse(todoId)
				.orElseThrow(() -> new CustomException(TodoErrorCode.T01_001));

		if (!todo.getUserId().equals(userId)) {
			throw new CustomException(TodoErrorCode.T01_003);
		}

		todo.softDelete();
		if (todo.getType() == TodoType.RECURRING && isAllScope(scope)) {
			todoRepository.findAllByUserIdAndTitleAndTypeAndIsDeletedFalse(userId, todo.getTitle(), TodoType.NORMAL)
					.forEach(Todo::softDelete);
		}
	}

	@Override
	@Transactional
	public TodoDetailResp update(Long userId, Long todoId, TodoUpdateReq req) {
		Todo todo = todoRepository.findByTodoIdAndIsDeletedFalse(todoId)
				.orElseThrow(() -> new CustomException(TodoErrorCode.T04_001));

		if (!todo.getUserId().equals(userId)) {
			throw new CustomException(TodoErrorCode.T04_003);
		}

		if (todo.getStatus() == TodoStatus.IN_PROGRESS || todo.getStatus() == TodoStatus.DONE) {
			throw new CustomException(TodoErrorCode.T04_004);
		}

		Long categoryId = todo.getCategoryId();
		String categoryName = null;
		if (req.category() != null && StringUtils.hasText(req.category())) {
			Category category = categoryRepository.findByCategoryNameAndUserId(req.category(), userId)
					.orElseThrow(() -> new CustomException(TodoErrorCode.T04_005));
			categoryId = category.getCategoryId();
			categoryName = category.getCategoryName();
		} else {
			if (todo.getCategoryId() != null) {
				categoryName = categoryRepository.findById(todo.getCategoryId())
						.map(Category::getCategoryName)
						.orElse(null);
			}
		}

		TodoType finalType = req.type() != null ? req.type() : todo.getType();
		Integer finalPeriod = req.period() != null ? req.period() : todo.getPeriod();
		if (finalType == TodoType.RECURRING && finalPeriod == null) {
			throw new CustomException(TodoErrorCode.T04_004);
		}

		todo.update(
				req.title(),
				req.content(),
				categoryId,
				req.type(),
				req.startDate(),
				req.endDate(),
				req.period()
		);

		int count = (int) snoozeHistoryRepository.countByTodoId(todo.getTodoId());
		return TodoDetailResp.from(todo, categoryName, count);
	}

	@Override
	@Transactional
	public TodoDetailResp changeStatus(Long userId, Long todoId, TodoStatusChangeReq req) {
		Todo todo = todoRepository.findByTodoIdAndIsDeletedFalse(todoId)
				.orElseThrow(() -> new CustomException(TodoErrorCode.T03_001));

		if (!todo.getUserId().equals(userId)) {
			throw new CustomException(TodoErrorCode.T03_003);
		}

		if (todo.getType() == TodoType.RECURRING) {
			throw new CustomException(TodoErrorCode.T03_004);
		}

		todo.changeStatus(req.status());

		String categoryName = null;
		if (todo.getCategoryId() != null) {
			categoryName = categoryRepository.findById(todo.getCategoryId())
					.map(Category::getCategoryName)
					.orElse(null);
		}

		// TODO: DONE 상태 변경 시 Tamagotchi 도메인 경험치 연동 필요 — Tamagotchi 이벤트 발행 추가 예정

		int count = (int) snoozeHistoryRepository.countByTodoId(todo.getTodoId());
		return TodoDetailResp.from(todo, categoryName, count);
	}

	@Override
	@Transactional
	public TodoDetailResp changePriority(Long userId, Long todoId, TodoPriorityChangeReq req) {
		Todo todo = todoRepository.findByTodoIdAndIsDeletedFalse(todoId)
				.orElseThrow(() -> new CustomException(TodoErrorCode.T07_001));

		if (!todo.getUserId().equals(userId)) {
			throw new CustomException(TodoErrorCode.T07_003);
		}

		todo.changePriority(req.priority());

		String categoryName = null;
		if (todo.getCategoryId() != null) {
			categoryName = categoryRepository.findById(todo.getCategoryId())
					.map(Category::getCategoryName)
					.orElse(null);
		}

		int count = (int) snoozeHistoryRepository.countByTodoId(todo.getTodoId());
		return TodoDetailResp.from(todo, categoryName, count);
	}

	@Override
	@Transactional(readOnly = true)
	public TodoSearchResp search(Long userId, TodoSearchReq req) {
		// 기본값 처리
		String sortParam = req.sort() != null ? req.sort() : "date";
		int page = req.page() != null ? req.page() : 0;
		int size = req.size() != null ? req.size() : 20;

		// Specification 조합: ownerAndActive + byKeyword(q)
		Specification<Todo> spec = TodoSpecifications.ownerAndActive(userId)
				.and(TodoSpecifications.byKeyword(req.q()));

		// Sort 결정
		Sort sort = resolveSearchSort(sortParam);

		// 페이지네이션 조회
		Page<Todo> pageResult = todoRepository.findAll(spec, PageRequest.of(page, size, sort));

		// 카테고리 벌크 조회 (N+1 방지)
		Set<Long> categoryIds = pageResult.getContent().stream()
				.map(Todo::getCategoryId)
				.filter(id -> id != null)
				.collect(Collectors.toSet());

		Map<Long, String> categoryNameById = categoryIds.isEmpty()
				? Map.of()
				: categoryRepository.findAllById(categoryIds).stream()
						.collect(Collectors.toMap(Category::getCategoryId, Category::getCategoryName));

		// snooze 횟수 벌크 조회
		Set<Long> todoIds = pageResult.getContent().stream()
				.map(Todo::getTodoId)
				.collect(Collectors.toSet());

		Map<Long, Integer> snoozeCountByTodoId = todoIds.isEmpty()
				? Map.of()
				: snoozeHistoryRepository.countByTodoIdIn(todoIds).stream()
						.collect(Collectors.toMap(
								SnoozeCountProjection::getTodoId,
								p -> p.getCnt().intValue()
						));

		return TodoSearchResp.from(pageResult, categoryNameById, snoozeCountByTodoId);
	}

	private Sort resolveSearchSort(String sortParam) {
		return switch (sortParam.toLowerCase()) {
			case "category" -> Sort.by(Order.asc("categoryId").nullsLast(), Order.asc("startDate"));
			default -> Sort.by(Order.asc("startDate"), Order.asc("todoId"));
		};
	}

	@Override
	@Transactional
	public TodoDetailResp snooze(Long userId, Long todoId, TodoSnoozeReq req) {
		Todo todo = todoRepository.findByTodoIdAndIsDeletedFalse(todoId)
				.orElseThrow(() -> new CustomException(TodoErrorCode.T05_001));

		if (!todo.getUserId().equals(userId)) {
			throw new CustomException(TodoErrorCode.T05_003);
		}

		if (todo.getType() == TodoType.RECURRING) {
			todo = materializeRecurringInstance(userId, todo, req);
		}

		LocalDate fromDate = todo.getStartDate();
		todo.snooze();  // startDate +=1, endDate +=1 if not null

		snoozeHistoryRepository.save(SnoozeHistory.create(
				todo.getTodoId(), userId, fromDate, todo.getStartDate()));

		int count = (int) snoozeHistoryRepository.countByTodoId(todo.getTodoId());
		String categoryName = null;
		if (todo.getCategoryId() != null) {
			categoryName = categoryRepository.findById(todo.getCategoryId())
					.map(Category::getCategoryName)
					.orElse(null);
		}
		return TodoDetailResp.from(todo, categoryName, count);
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

	private boolean isAllScope(String scope) {
		return StringUtils.hasText(scope) && "all".equalsIgnoreCase(scope);
	}

	private Todo materializeRecurringInstance(Long userId, Todo master, TodoSnoozeReq req) {
		LocalDate occurrenceDate = req != null ? req.occurrenceDate() : null;
		if (occurrenceDate == null || !isOccurrenceOfMaster(master, occurrenceDate)) {
			throw new CustomException(TodoErrorCode.T05_004);
		}

		return todoRepository.findByUserIdAndTitleAndStartDateAndIsDeletedFalse(userId, master.getTitle(), occurrenceDate)
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
