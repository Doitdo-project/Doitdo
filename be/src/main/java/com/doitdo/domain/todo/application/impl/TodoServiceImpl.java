package com.doitdo.domain.todo.application.impl;

import com.doitdo.domain.todo.api.dto.req.TodoCalendarReq;
import com.doitdo.domain.todo.api.dto.req.TodoCreateReq;
import com.doitdo.domain.todo.api.dto.req.TodoListReq;
import com.doitdo.domain.todo.api.dto.req.TodoPriorityChangeReq;
import com.doitdo.domain.todo.api.dto.req.TodoSearchReq;
import com.doitdo.domain.todo.api.dto.req.TodoSnoozeReq;
import com.doitdo.domain.todo.api.dto.req.TodoStatusChangeReq;
import com.doitdo.domain.todo.api.dto.req.TodoUpdateReq;
import com.doitdo.domain.todo.api.dto.resp.TodoCalendarResp;
import com.doitdo.domain.todo.api.dto.resp.TodoDetailResp;
import com.doitdo.domain.todo.api.dto.resp.TodoListResp;
import com.doitdo.domain.todo.api.dto.resp.TodoSearchResp;
import com.doitdo.domain.todo.application.RecurrenceService;
import com.doitdo.domain.todo.application.TodoService;
import com.doitdo.domain.todo.entity.Category;
import com.doitdo.domain.todo.entity.PaletteColor;
import com.doitdo.domain.todo.entity.SnoozeHistory;
import com.doitdo.domain.todo.entity.Todo;
import com.doitdo.domain.todo.entity.Todo.TodoStatus;
import com.doitdo.domain.todo.entity.Todo.TodoType;
import com.doitdo.domain.todo.event.TodoCompletedEvent;
import com.doitdo.domain.todo.event.TodoSnoozedEvent;
import com.doitdo.domain.todo.repository.CategoryRepository;
import com.doitdo.domain.todo.repository.PaletteColorRepository;
import com.doitdo.domain.todo.repository.SnoozeHistoryRepository;
import com.doitdo.domain.todo.repository.SnoozeHistoryRepository.SnoozeCountProjection;
import com.doitdo.domain.todo.repository.TodoRepository;
import com.doitdo.domain.todo.repository.TodoListQueryRepository;
import com.doitdo.domain.todo.repository.TodoSpecifications;
import com.doitdo.domain.todo.repository.projection.TodoListRow;
import com.doitdo.domain.streak.application.UserStreakService;
import com.doitdo.global.cache.CacheEvictHelper;
import com.doitdo.global.exception.CustomException;
import com.doitdo.global.exception.TodoErrorCode;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.EnumSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cache.annotation.Cacheable;
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
@Slf4j
public class TodoServiceImpl implements TodoService {

	private static final ZoneId SEOUL = ZoneId.of("Asia/Seoul");

	private final TodoRepository todoRepository;
	private final TodoListQueryRepository todoListQueryRepository;
	private final CategoryRepository categoryRepository;
	private final PaletteColorRepository paletteColorRepository;
	private final SnoozeHistoryRepository snoozeHistoryRepository;
	private final RecurrenceService recurrenceService;
	private final UserStreakService userStreakService;
	private final ApplicationEventPublisher eventPublisher;
	private final CacheEvictHelper cacheEvictHelper;

	@Override
	@Transactional(readOnly = true)
	@Cacheable(
			value = "todos:list",
			key = "#userId + ':' + (#req.view ?: 'all') + ':' + (#req.type ?: 'X') + ':' "
					+ "+ (#req.status ?: 'X') + ':' + (#req.category ?: 'X') + ':' "
					+ "+ (#req.sort ?: 'X') + ':' + (#req.q != null ? #req.q.hashCode() : 'X') + ':' "
					+ "+ (#req.date != null ? #req.date : T(java.time.LocalDate).now(T(java.time.ZoneId).of('Asia/Seoul')))",
			unless = "#result == null"
	)
	public TodoListResp list(Long userId, TodoListReq req) {
		// 기준일: date 파라미터가 있으면 그 날짜, 없으면 오늘
		LocalDate baseDate = req.date() != null ? req.date() : LocalDate.now(SEOUL);
		LocalDate today = LocalDate.now(SEOUL);

		List<TodoListRow> rows = todoListQueryRepository.findListRows(
				userId,
				req.view(),
				req.status(),
				req.category(),
				req.type(),
				baseDate,
				today,
				req.q(),
				req.sort());

		Map<String, Integer> activeColorByName = buildActiveCategoryColorIdByName(userId);
		Map<Integer, String> hexByColorId = buildPaletteHexByColorId();

		return new TodoListResp(rows.stream()
				.map(row -> toTodoDetailResp(row, activeColorByName, hexByColorId))
				.toList());
	}

	@Override
	@Transactional(readOnly = true)
	public TodoCalendarResp calendar(Long userId, TodoCalendarReq req) {
		return recurrenceService.calendar(userId, req);
	}

	private static TodoDetailResp toTodoDetailResp(
			TodoListRow row,
			Map<String, Integer> activeColorIdByName,
			Map<Integer, String> hexByColorId) {
		String colorHex = resolveColorHex(
				row.categoryName(), row.categoryColorId(), activeColorIdByName, hexByColorId);
		return new TodoDetailResp(
				row.todoId(),
				row.title(),
				row.content(),
				row.categoryName(),
				colorHex,
				row.type(),
				row.priority(),
				row.alertTime(),
				row.startDate(),
				row.endDate(),
				toDaysOfWeekCodes(row.daysOfWeekRaw()),
				row.status(),
				row.updatedAt(),
				(int) row.snoozeCount()
		);
	}

	/**
	 * 카테고리 색상 결정 규칙 (다건 응답 빌드 시 사용).
	 * - todo.categoryName 이 null 이면 hex 도 null.
	 * - 같은 이름의 활성 카테고리가 있으면 그 색상이 todo 의 스냅샷 색을 override.
	 * - 활성 카테고리에 같은 이름이 없으면 스냅샷 색을 사용 (삭제된 카테고리 정책).
	 */
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

	private Map<String, Integer> buildActiveCategoryColorIdByName(Long userId) {
		return categoryRepository.findAllByUserIdOrderByCategoryIdAsc(userId).stream()
				.collect(Collectors.toMap(Category::getCategoryName, Category::getColorId, (a, b) -> a));
	}

	private Map<Integer, String> buildPaletteHexByColorId() {
		return paletteColorRepository.findAll().stream()
				.collect(Collectors.toMap(PaletteColor::getColorId, PaletteColor::getColor));
	}

	/**
	 * 단건 응답 빌드 시 색상 결정.
	 * 활성 카테고리 lookup 1회 + 팔레트 lookup 1회 (최대 2 쿼리).
	 */
	private String resolveColorHexForTodo(Long userId, Todo todo) {
		if (todo.getCategoryName() == null) {
			return null;
		}
		Integer colorId = categoryRepository.findByCategoryNameAndUserId(todo.getCategoryName(), userId)
				.map(Category::getColorId)
				.orElse(todo.getCategoryColorId());
		if (colorId == null) {
			return null;
		}
		return paletteColorRepository.findById(colorId)
				.map(PaletteColor::getColor)
				.orElse(null);
	}

	private static List<String> toDaysOfWeekCodes(String daysOfWeekRaw) {
		if (!StringUtils.hasText(daysOfWeekRaw)) {
			return List.of();
		}
		return Arrays.stream(daysOfWeekRaw.split(","))
				.map(String::trim)
				.filter(token -> !token.isEmpty())
				.map(Todo::toDayOfWeek)
				.sorted()
				.map(Todo::toDayOfWeekCode)
				.toList();
	}

	@Override
	@Transactional(readOnly = true)
	@Cacheable(value = "todos:item", key = "#userId + ':' + #todoId", unless = "#result == null")
	public TodoDetailResp detail(Long userId, Long todoId) {
		Todo todo = todoRepository.findByTodoIdAndIsDeletedFalse(todoId)
				.orElseThrow(() -> new CustomException(TodoErrorCode.T00_001));

		if (!todo.getUserId().equals(userId)) {
			throw new CustomException(TodoErrorCode.T00_003);
		}

		String colorHex = resolveColorHexForTodo(userId, todo);
		int count = (int) snoozeHistoryRepository.countByTodoId(todo.getTodoId());
		return TodoDetailResp.from(todo, todo.getCategoryName(), colorHex, count);
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
		Integer categoryColorId = null;
		if (StringUtils.hasText(req.category())) {
			Category category = categoryRepository.findByCategoryNameAndUserId(req.category(), userId)
					.orElseThrow(() -> new CustomException(TodoErrorCode.T06_003));
			categoryId = category.getCategoryId();
			categoryName = category.getCategoryName();
			categoryColorId = category.getColorId();
		}

		int priority = req.priority() != null ? req.priority() : nextPriority(userId, type);

		Todo todo = todoRepository.save(
				Todo.create(userId, categoryId, categoryName, categoryColorId,
						req.title(), req.content(),
						type, priority, req.alertTime(), startDate, req.endDate(), daysOfWeek)
		);

		log.info("event=TODO_CREATED userId={} todoId={}", userId, todo.getTodoId());
		cacheEvictHelper.evictUserTodosAfterCommit(userId);

		// 방금 카테고리에서 색을 가져왔으므로 추가 lookup 없이 hex 만 변환.
		String colorHex = categoryColorId != null
				? paletteColorRepository.findById(categoryColorId).map(PaletteColor::getColor).orElse(null)
				: null;
		// 새 TODO 이므로 snooze 이력 없음 — count=0 하드코딩 (DB 조회 불필요)
		return TodoDetailResp.from(todo, categoryName, colorHex, 0);
	}

	private int nextPriority(Long userId, TodoType type) {
		int maxPriority = type == TodoType.SOMEDAY
				? todoRepository.findMaxPriorityForSomeday(userId)
				: todoRepository.findMaxPriorityForNonSomeday(userId);
		return maxPriority + 1;
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
		log.info("event=TODO_DELETED userId={} todoId={} scope={}", userId, todo.getTodoId(), scope);
		cacheEvictHelper.evictUserTodosAfterCommit(userId);
		cacheEvictHelper.evictTodoItemAfterCommit(userId, todoId);
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
		String categoryName = todo.getCategoryName();
		Integer categoryColorId = todo.getCategoryColorId();
		if (req.category() != null && StringUtils.hasText(req.category())) {
			Category category = categoryRepository.findByCategoryNameAndUserId(req.category(), userId)
					.orElseThrow(() -> new CustomException(TodoErrorCode.T04_005));
			categoryId = category.getCategoryId();
			categoryName = category.getCategoryName();
			categoryColorId = category.getColorId();
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
				categoryName,
				categoryColorId,
				finalType,
				finalStartDate,
				req.endDate(),
				requestedDaysOfWeek,
				req.alertTime()
		);
		if (Boolean.TRUE.equals(req.clearAlertTime())) {
			todo.clearAlertTime();
		}

		log.info("event=TODO_UPDATED userId={} todoId={}", userId, todo.getTodoId());
		cacheEvictHelper.evictUserTodosAfterCommit(userId);
		cacheEvictHelper.evictTodoItemAfterCommit(userId, todoId);

		String colorHex = resolveColorHexForTodo(userId, todo);
		int count = (int) snoozeHistoryRepository.countByTodoId(todo.getTodoId());
		return TodoDetailResp.from(todo, todo.getCategoryName(), colorHex, count);
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
			if (req.occurrenceDate() == null) {
				throw new CustomException(TodoErrorCode.T03_004);
			}
			todo = recurrenceService.materializeRecurringOccurrence(userId, todo, req.occurrenceDate());
		}

		TodoStatus beforeStatus = todo.getStatus();
		todo.changeStatus(req.status());

		// DONE 으로 새로 진입한 경우에만 streak 갱신 + Tamagotchi exp 이벤트 발행.
		// - streak: UserStreakService 가 동기 갱신. 엔티티 내부에서도 당일 중복 no-op.
		// - exp: 리스너가 AFTER_COMMIT + REQUIRES_NEW 로 처리 (멱등성은 Todo.expGranted 로 보장).
		// - 가산 실패해도 Todo DONE 은 커밋 유지 (사용자 UX 우선)
		if (beforeStatus != TodoStatus.DONE && req.status() == TodoStatus.DONE) {
			todo.markFirstCompletedIfAbsent(LocalDate.now(SEOUL));
			userStreakService.recordActivity(userId);
			eventPublisher.publishEvent(new TodoCompletedEvent(userId, todo.getTodoId()));
			log.info("event=TODO_COMPLETED userId={} todoId={}", userId, todo.getTodoId());
		}
		log.info("event=TODO_STATUS_CHANGED userId={} todoId={} status={}",
				userId, todo.getTodoId(), req.status());
		cacheEvictHelper.evictUserTodosAfterCommit(userId);
		cacheEvictHelper.evictTodoItemAfterCommit(userId, todoId);
		cacheEvictHelper.evictTamagotchiCurrentAfterCommit(userId);

		String colorHex = resolveColorHexForTodo(userId, todo);
		int count = (int) snoozeHistoryRepository.countByTodoId(todo.getTodoId());
		return TodoDetailResp.from(todo, todo.getCategoryName(), colorHex, count);
	}

	@Override
	@Transactional
	public TodoDetailResp changePriority(Long userId, Long todoId, TodoPriorityChangeReq req) {
		Todo todo = todoRepository.findByTodoIdAndIsDeletedFalse(todoId)
				.orElseThrow(() -> new CustomException(TodoErrorCode.T07_001));

		if (!todo.getUserId().equals(userId)) {
			throw new CustomException(TodoErrorCode.T07_003);
		}

		List<Todo> reorderTargets = new ArrayList<>(todo.getType() == TodoType.SOMEDAY
				? todoRepository.findReorderTargetsForSomeday(userId)
				: todoRepository.findReorderTargetsForNonSomeday(userId));
		reorderTargets.removeIf(item -> item.getTodoId().equals(todoId));

		int requestedPriority = req.priority() == null ? reorderTargets.size() + 1 : req.priority();
		int targetIndex = Math.max(0, Math.min(requestedPriority - 1, reorderTargets.size()));
		reorderTargets.add(targetIndex, todo);

		for (int i = 0; i < reorderTargets.size(); i++) {
			reorderTargets.get(i).changePriority(i + 1);
		}
		cacheEvictHelper.evictUserTodosAfterCommit(userId);
		cacheEvictHelper.evictTodoItemAfterCommit(userId, todoId);

		String colorHex = resolveColorHexForTodo(userId, todo);
		int count = (int) snoozeHistoryRepository.countByTodoId(todo.getTodoId());
		return TodoDetailResp.from(todo, todo.getCategoryName(), colorHex, count);
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

		// 카테고리 색상 결정용 맵 (활성 카테고리 + 팔레트 hex)
		Map<String, Integer> activeColorByName = buildActiveCategoryColorIdByName(userId);
		Map<Integer, String> hexByColorId = buildPaletteHexByColorId();

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

		List<TodoDetailResp> items = pageResult.getContent().stream()
				.map(todo -> TodoDetailResp.from(
						todo,
						todo.getCategoryName(),
						resolveColorHex(todo.getCategoryName(), todo.getCategoryColorId(),
								activeColorByName, hexByColorId),
						snoozeCountByTodoId.getOrDefault(todo.getTodoId(), 0)
				))
				.toList();

		return new TodoSearchResp(
				items,
				pageResult.getNumber(),
				pageResult.getSize(),
				pageResult.getTotalElements(),
				pageResult.getTotalPages()
		);
	}

	private Sort resolveSearchSort(String sortParam) {
		return switch (sortParam.toLowerCase()) {
			case "category" -> Sort.by(Order.asc("categoryName"), Order.asc("startDate"), Order.asc("todoId"));
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

		todo = recurrenceService.materializeRecurringIfNeeded(userId, todo, req);

		LocalDate fromDate = todo.getStartDate();
		todo.snooze();  // startDate +=1, endDate +=1 if not null

		snoozeHistoryRepository.save(SnoozeHistory.create(
				todo.getTodoId(), userId, fromDate, todo.getStartDate()));

		eventPublisher.publishEvent(new TodoSnoozedEvent(userId, todo.getTodoId(), fromDate, todo.getStartDate()));
		log.info("event=TODO_SNOOZED userId={} todoId={} fromDate={} toDate={}",
				userId, todo.getTodoId(), fromDate, todo.getStartDate());
		cacheEvictHelper.evictUserTodosAfterCommit(userId);
		cacheEvictHelper.evictTodoItemAfterCommit(userId, todoId);
		if (!todoId.equals(todo.getTodoId())) {
			cacheEvictHelper.evictTodoItemAfterCommit(userId, todo.getTodoId());
		}

		int count = (int) snoozeHistoryRepository.countByTodoId(todo.getTodoId());
		String colorHex = resolveColorHexForTodo(userId, todo);
		return TodoDetailResp.from(todo, todo.getCategoryName(), colorHex, count);
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
