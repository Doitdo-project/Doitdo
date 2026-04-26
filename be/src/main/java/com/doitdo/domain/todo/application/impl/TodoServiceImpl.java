package com.doitdo.domain.todo.application.impl;

import com.doitdo.domain.todo.api.dto.req.TodoCalendarReq;
import com.doitdo.domain.todo.api.dto.req.TodoCreateReq;
import com.doitdo.domain.todo.api.dto.req.TodoListReq;
import com.doitdo.domain.todo.api.dto.req.TodoPriorityChangeReq;
import com.doitdo.domain.todo.api.dto.req.TodoSearchReq;
import com.doitdo.domain.todo.api.dto.req.TodoSnoozeReq;
import com.doitdo.domain.todo.api.dto.req.TodoStatusChangeReq;
import com.doitdo.domain.todo.api.dto.req.TodoUpdateReq;
import com.doitdo.domain.todo.event.TodoCompletedEvent;
import com.doitdo.domain.todo.event.TodoSnoozedEvent;
import com.doitdo.domain.todo.api.dto.resp.TodoCalendarResp;
import com.doitdo.domain.todo.api.dto.resp.TodoDetailResp;
import com.doitdo.domain.todo.api.dto.resp.TodoListResp;
import com.doitdo.domain.todo.api.dto.resp.TodoSearchResp;
import com.doitdo.domain.todo.application.RecurrenceService;
import com.doitdo.domain.todo.application.TodoService;
import com.doitdo.domain.todo.entity.Category;
import com.doitdo.domain.todo.entity.SnoozeHistory;
import com.doitdo.domain.todo.entity.Todo;
import com.doitdo.domain.todo.entity.Todo.TodoStatus;
import com.doitdo.domain.todo.entity.Todo.TodoType;
import com.doitdo.domain.todo.repository.CategoryRepository;
import com.doitdo.domain.todo.repository.SnoozeHistoryRepository;
import com.doitdo.domain.todo.repository.SnoozeHistoryRepository.SnoozeCountProjection;
import com.doitdo.domain.streak.application.UserStreakService;
import com.doitdo.domain.todo.repository.TodoRepository;
import com.doitdo.domain.todo.repository.TodoSpecifications;
import com.doitdo.global.exception.CustomException;
import com.doitdo.global.exception.TodoErrorCode;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.util.EnumSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import org.springframework.context.ApplicationEventPublisher;
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
	private final RecurrenceService recurrenceService;
	private final UserStreakService userStreakService;
	private final ApplicationEventPublisher eventPublisher;

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
		return recurrenceService.calendar(userId, req);
	}

	private Sort resolveSort(String sortParam) {
		if (sortParam == null) {
			return Sort.by(Order.asc("startDate").nullsLast(), Order.asc("todoId"));
		}
		return switch (sortParam.toLowerCase()) {
			case "category" -> Sort.by(Order.asc("categoryId"), Order.asc("startDate").nullsLast(), Order.asc("todoId"));
			case "priority" -> Sort.by(Order.desc("priority"), Order.asc("startDate").nullsLast(), Order.asc("todoId"));
			default -> Sort.by(Order.asc("startDate").nullsLast(), Order.asc("todoId"));
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
		Set<DayOfWeek> daysOfWeek = parseDaysOfWeek(req.daysOfWeek());
		TodoType type = req.type();
		if (type == null) {
			throw new CustomException(TodoErrorCode.T06_002);
		}
		LocalDate startDate = normalizeStartDate(type, req.startDate());
		validateStartDate(type, startDate, true);
		validateRecurringDays(type, startDate, daysOfWeek);

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
						type, priority, req.alertTime(), startDate, req.endDate(), daysOfWeek)
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
			todoRepository.findAllByUserIdAndMasterTodoIdAndIsDeletedFalse(userId, todo.getTodoId())
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

		Set<DayOfWeek> requestedDaysOfWeek = req.daysOfWeek() != null ? parseDaysOfWeek(req.daysOfWeek()) : null;
		TodoType finalType = req.type() != null ? req.type() : todo.getType();
		LocalDate finalStartDate = normalizeStartDate(finalType, req.startDate() != null ? req.startDate() : todo.getStartDate());
		Set<DayOfWeek> finalDaysOfWeek = requestedDaysOfWeek != null ? requestedDaysOfWeek : todo.getDaysOfWeek();
		validateStartDate(finalType, finalStartDate, false);
		validateRecurringDays(finalType, finalStartDate, finalDaysOfWeek);

		todo.update(
				req.title(),
				req.content(),
				categoryId,
				finalType,
				finalStartDate,
				req.endDate(),
				requestedDaysOfWeek,
				req.alertTime()
		);
		if (Boolean.TRUE.equals(req.clearAlertTime())) {
			todo.clearAlertTime();
		}

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

		TodoStatus beforeStatus = todo.getStatus();
		todo.changeStatus(req.status());

		// DONE 으로 새로 진입한 경우에만 streak 갱신 + Tamagotchi exp 이벤트 발행.
		// - streak: UserStreakService 가 동기 갱신. 엔티티 내부에서도 당일 중복 no-op.
		// - exp: 리스너가 AFTER_COMMIT + REQUIRES_NEW 로 처리 (멱등성은 Todo.expGranted 로 보장).
		// - 가산 실패해도 Todo DONE 은 커밋 유지 (사용자 UX 우선)
		if (beforeStatus != TodoStatus.DONE && req.status() == TodoStatus.DONE) {
			userStreakService.recordActivity(userId);
			eventPublisher.publishEvent(new TodoCompletedEvent(userId, todo.getTodoId()));
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
			case "category" -> Sort.by(Order.asc("categoryId").nullsLast(), Order.asc("startDate").nullsLast(), Order.asc("todoId"));
			default -> Sort.by(Order.asc("startDate").nullsLast(), Order.asc("todoId"));
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

		todo = recurrenceService.materializeRecurringIfNeeded(userId, todo, req);

		LocalDate fromDate = todo.getStartDate();
		todo.snooze();  // startDate +=1, endDate +=1 if not null

		snoozeHistoryRepository.save(SnoozeHistory.create(
				todo.getTodoId(), userId, fromDate, todo.getStartDate()));

		eventPublisher.publishEvent(new TodoSnoozedEvent(userId, todo.getTodoId(), fromDate, todo.getStartDate()));

		int count = (int) snoozeHistoryRepository.countByTodoId(todo.getTodoId());
		String categoryName = null;
		if (todo.getCategoryId() != null) {
			categoryName = categoryRepository.findById(todo.getCategoryId())
					.map(Category::getCategoryName)
					.orElse(null);
		}
		return TodoDetailResp.from(todo, categoryName, count);
	}

	private boolean isAllScope(String scope) {
		return StringUtils.hasText(scope) && "all".equalsIgnoreCase(scope);
	}

	private Set<DayOfWeek> parseDaysOfWeek(Set<String> daysOfWeek) {
		if (daysOfWeek == null) {
			return null;
		}
		EnumSet<DayOfWeek> parsed = EnumSet.noneOf(DayOfWeek.class);
		daysOfWeek.forEach(code -> parsed.add(Todo.toDayOfWeek(code)));
		return parsed;
	}

	private void validateRecurringDays(TodoType type, LocalDate startDate, Set<DayOfWeek> daysOfWeek) {
		if (type != TodoType.RECURRING) {
			return;
		}
		if (daysOfWeek == null || daysOfWeek.isEmpty()) {
			throw new CustomException(TodoErrorCode.TODO_RECURRING_DAYS_OF_WEEK_REQUIRED);
		}
		if (startDate != null && !daysOfWeek.contains(startDate.getDayOfWeek())) {
			throw new CustomException(TodoErrorCode.TODO_RECURRING_START_DATE_DAY_MISMATCH);
		}
	}

	private void validateStartDate(TodoType type, LocalDate startDate, boolean create) {
		if (type != TodoType.SOMEDAY && startDate == null) {
			throw new CustomException(create ? TodoErrorCode.T06_002 : TodoErrorCode.T04_006);
		}
	}

	private LocalDate normalizeStartDate(TodoType type, LocalDate startDate) {
		return type == TodoType.SOMEDAY ? null : startDate;
	}
}
