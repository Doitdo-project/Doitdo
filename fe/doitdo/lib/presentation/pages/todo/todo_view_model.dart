import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:doitdo/presentation/models/todo.dart';
import 'package:doitdo/presentation/pages/todo/todo_state.dart';
import 'package:doitdo/domain/repositories/todo_repository.dart';
import 'package:doitdo/presentation/providers/app_data_providers.dart';
import 'package:doitdo/data/models/todo_update_request_dto.dart';

class TodoViewModel extends StateNotifier<TodoState> {
  TodoViewModel(this._repository)
      : super(TodoState(
    // ✅ [핵심 수정 1] 초기 selectedDay 를 오늘로 설정
    //    null 이면 _updateDisplayedTodos() 에서 filteredTodos = [] 가 되어
    //    fetchTodos() 완료 후 onPageChanged 타이밍에 모든 할 일이 '오늘의 할 일'에 몰림
    selectedDay: DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day),
    focusedDay: DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day),
  )) {
    fetchTodos();
    fetchCalendarData();
  }

  final TodoRepository _repository;

  // ─────────────────────────────────────────────
  // 서버 카테고리명 → CategoryColorKey 변환
  // ─────────────────────────────────────────────
  static CategoryColorKey _colorKey(String? category) {
    switch (category) {
      case '운동': return CategoryColorKey.exercise;
      case '업무': return CategoryColorKey.work;
      case '건강': return CategoryColorKey.health;
      case '취미': return CategoryColorKey.hobby;
      case '공부': return CategoryColorKey.study;
      default:     return CategoryColorKey.etc;
    }
  }

  // ─────────────────────────────────────────────
  // [핵심] 필터 + 날짜 기준 화면 목록 갱신
  // ─────────────────────────────────────────────
  void _updateDisplayedTodos() {
    final filter     = state.currentFilter;
    final selectedDay = state.selectedDay;
    final now  = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    List<Todo> filteredTodos   = state.allTodos;
    List<Todo> filteredSomeday = state.allSomedayTodos;

    // ── 1. 날짜 기반 할 일 필터링 ──────────────
    switch (filter) {
      case 'upcoming':
      // 오늘 이후 할 일
        filteredTodos = filteredTodos
            .where((t) => t.date != null && t.date!.isAfter(today))
            .toList();
        filteredSomeday = []; // 날짜 없는 건 예정/지난에 미표시
      case 'past':
      // 오늘 이전 할 일
        filteredTodos = filteredTodos
            .where((t) => t.date != null && t.date!.isBefore(today))
            .toList();
        filteredSomeday = [];
      default:
      // all / todo / done → 선택 날짜 기준
        if (selectedDay != null) {
          filteredTodos = filteredTodos
              .where((t) => t.date != null && isSameDay(t.date!, selectedDay))
              .toList();
        } else {
          filteredTodos = [];
        }
    }

    // ── 2. 상태 필터 (todo / done) ──────────────
    if (filter == 'todo') {
      filteredTodos   = filteredTodos.where((t) => !t.isDone).toList();
      filteredSomeday = filteredSomeday.where((t) => !t.isDone).toList();
    } else if (filter == 'done') {
      filteredTodos   = filteredTodos.where((t) => t.isDone).toList();
      filteredSomeday = filteredSomeday.where((t) => t.isDone).toList();
    }

    state = state.copyWith(
      todos:        filteredTodos,
      somedayTodos: filteredSomeday,
    );
  }

  // ─────────────────────────────────────────────
  // [T02] 서버에서 전체 목록 가져와 날짜 유무로 분류 및 정렬
  // ─────────────────────────────────────────────
  Future<void> fetchTodos() async {
    final result = await AsyncValue.guard(
          () => _repository.getTodos(view: 'all'),
    );

    if (result.hasValue) {
      final items = result.value!.items;

      // [추가] 서버 데이터를 priority(우선순위) 오름차순으로 정렬
      // 값이 없을 경우(null) 가장 뒤로 보내기 위해 999를 기본값으로 사용합니다.
      final sortedItems = List.of(items)
        ..sort((a, b) => (a.priority ?? 999).compareTo(b.priority ?? 999));

      // 정렬된 sortedItems를 바탕으로 Todo 객체 생성
      final allFetched = sortedItems.map((dto) => Todo(
        id:       dto.todoId.toString(),
        title:    dto.title,
        isDone:   dto.status == 'DONE',
        category: TodoCategory(
          name:     dto.category ?? '기타',
          colorKey: _colorKey(dto.category),
        ),
        date: dto.startDate != null
            ? DateTime.tryParse(dto.startDate!)
            : null,
        rangeEnd: dto.endDate != null
            ? DateTime.tryParse(dto.endDate!)
            : null,
      )).toList();

      // 날짜 유무에 따라 마스터 리스트 분류
      state = state.copyWith(
        allTodos: allFetched
            .where((t) => t.date != null || t.rangeEnd != null)
            .toList(),
        allSomedayTodos: allFetched
            .where((t) => t.date == null && t.rangeEnd == null)
            .toList(),
      );

      // 분류 완료 후 화면 목록 갱신
      _updateDisplayedTodos();
      print('데이터 정렬 및 불러오기 완료: ${allFetched.length}개');
    }
  }

  // ─────────────────────────────────────────────
  // [T08] 캘린더 요약 데이터
  // ─────────────────────────────────────────────
  Future<void> fetchCalendarData() async {
    final focusedDay = state.focusedDay;
    final firstDay   = DateTime(focusedDay.year, focusedDay.month, 1);
    final lastDay    = DateTime(focusedDay.year, focusedDay.month + 1, 0);

    await AsyncValue.guard(
          () => _repository.getCalendarTodos(
        from: firstDay.toIso8601String().split('T')[0],
        to:   lastDay.toIso8601String().split('T')[0],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // 필터 / 캘린더 액션
  // ─────────────────────────────────────────────
  void setFilter(String filter) {
    state = state.copyWith(currentFilter: filter);
    _updateDisplayedTodos();
  }

  void onDaySelected(DateTime selected, DateTime focused) {
    state = state.copyWith(
      selectedDay: DateTime(selected.year, selected.month, selected.day),
      focusedDay:  focused,
    );
    _updateDisplayedTodos();
  }

  void onFormatChanged(CalendarFormat format) {
    state = state.copyWith(calendarFormat: format);
  }

  // ─────────────────────────────────────────────
  // 오늘의 할 일 (날짜 있음) CRUD
  // ─────────────────────────────────────────────
  void addTodo(Todo todo) {
    state = state.copyWith(allTodos: [...state.allTodos, todo]);
    _updateDisplayedTodos();
  }

  Future<void> toggleTodo(String id) async {
    final idx = state.allTodos.indexWhere((t) => t.id == id);
    if (idx == -1) return;

    final newStatus = state.allTodos[idx].isDone ? 'TODO' : 'DONE';
    state = state.copyWith(
      allTodos: state.allTodos
          .map((t) => t.id == id ? t.copyWith(isDone: !t.isDone) : t)
          .toList(),
    );
    _updateDisplayedTodos();

    await AsyncValue.guard(() => _repository.updateTodoStatus(id, newStatus));
  }

  Future<void> updateTodo(Todo updated) async {
    state = state.copyWith(
      allTodos: state.allTodos
          .map((t) => t.id == updated.id ? updated : t)
          .toList(),
    );
    _updateDisplayedTodos();

    await AsyncValue.guard(() => _repository.updateTodo(
      updated.id,
      TodoUpdateRequestDto(
        title:     updated.title,
        category:  updated.category.name,
        type: switch (updated.dateType) {
          TodoDateType.normal => 'NORMAL',
          TodoDateType.range  => 'PERIOD',
          TodoDateType.repeat => 'RECURRING',
        },
        startDate: updated.date?.toIso8601String().split('T')[0],
        endDate:   updated.rangeEnd?.toIso8601String().split('T')[0],
      ),
    ));
  }

  // 삭제 함수 (서버 통신 추가)
  Future<void> deleteTodo(String id, {String? scope}) async {
    // 1. 화면(로컬 상태)에서 먼저 즉시 지웁니다. (빠른 UX)
    state = state.copyWith(
      allTodos: state.allTodos.where((t) => t.id != id).toList(),
    );
    _updateDisplayedTodos();

    // 2. 백그라운드에서 서버로 삭제 API(T01)를 요청합니다.
    await AsyncValue.guard(() => _repository.deleteTodo(id, scope: scope));
  }

  // ─────────────────────────────────────────────
  // 오늘의 할 일 드래그 앤 드롭 우선순위 변경
  // ─────────────────────────────────────────────
  Future<void> reorderTodo(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) newIndex -= 1;
    final list = List<Todo>.from(state.todos);
    final Todo item = list.removeAt(oldIndex);
    list.insert(newIndex, item);

    // 1. 화면에 즉시 반영 (낙관적 업데이트)
    state = state.copyWith(todos: list);

    // 2. 서버에 변경된 우선순위 전송 (1부터 시작하는 순서로 계산)
    final newPriority = newIndex + 1;
    final response = await AsyncValue.guard(
            () => _repository.updateTodoPriority(item.id, newPriority)
    );

    // 3. ✅ 서버 업데이트 성공 시, 전체 데이터를 다시 불러와 마스터 리스트(allTodos) 싱크 맞추기
    if (!response.hasError) {
      fetchTodos();
    }
  }

  // ─────────────────────────────────────────────
  // 언제가 할 일 (날짜 없음) CRUD
  // ─────────────────────────────────────────────
  void addSomedayTodo(Todo todo) {
    state = state.copyWith(
        allSomedayTodos: [...state.allSomedayTodos, todo]);
    _updateDisplayedTodos();
  }

  Future<void> toggleSomedayTodo(String id) async {
    final idx = state.allSomedayTodos.indexWhere((t) => t.id == id);
    if (idx == -1) return;

    final newStatus = state.allSomedayTodos[idx].isDone ? 'TODO' : 'DONE';
    state = state.copyWith(
      allSomedayTodos: state.allSomedayTodos
          .map((t) => t.id == id ? t.copyWith(isDone: !t.isDone) : t)
          .toList(),
    );
    _updateDisplayedTodos();

    await AsyncValue.guard(() => _repository.updateTodoStatus(id, newStatus));
  }

  Future<void> updateSomedayTodo(Todo updated) async {
    state = state.copyWith(
      allSomedayTodos: state.allSomedayTodos
          .map((t) => t.id == updated.id ? updated : t)
          .toList(),
    );
    _updateDisplayedTodos();

    // ✅ [핵심 수정 4] 언제가 할 일은 startDate: null 로 전송 (백엔드 수정 완료)
    await AsyncValue.guard(() => _repository.updateTodo(
      updated.id,
      TodoUpdateRequestDto(
        title:     updated.title,
        category:  updated.category.name,
        type:      'NORMAL',
        startDate: null, // 날짜 없음 유지
        endDate:   null,
      ),
    ));
  }

  // 삭제 함수(서버 통신 추가)
  Future<void> deleteSomedayTodo(String id) async {
    // 1. 화면(로컬 상태)에서 먼저 즉시 지웁니다.
    state = state.copyWith(
      allSomedayTodos:
      state.allSomedayTodos.where((t) => t.id != id).toList(),
    );
    _updateDisplayedTodos();

    // 2. 백그라운드에서 서버로 삭제 API(T01)를 요청합니다.
    await AsyncValue.guard(() => _repository.deleteTodo(id));
  }

  // ─────────────────────────────────────────────
  // 언제가 할 일 드래그 앤 드롭 우선순위 변경
  // ─────────────────────────────────────────────
  Future<void> reorderSomedayTodo(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) newIndex -= 1;
    final list = List<Todo>.from(state.somedayTodos);
    final Todo item = list.removeAt(oldIndex);
    list.insert(newIndex, item);

    // 1. 화면에 즉시 반영
    state = state.copyWith(somedayTodos: list);

    // 2. 서버에 변경된 우선순위 전송
    final newPriority = newIndex + 1;
    final response = await AsyncValue.guard(
            () => _repository.updateTodoPriority(item.id, newPriority)
    );

    // 3. 서버 업데이트 성공 시 데이터 동기화
    if (!response.hasError) {
      fetchTodos();
    }
  }

  // ─────────────────────────────────────────────
  // 미루기 (오늘 → 내일로 이동) - 연동
  // ─────────────────────────────────────────────
  Future<void> snoozeTodo(String id) async {
    final idx = state.allTodos.indexWhere((t) => t.id == id);
    if (idx == -1) return;

    final target = state.allTodos[idx];
    if (target.isDone) return;

    // API 명세서 참고: 반복 일정은 현재 지원하지 않으므로 막아둡니다.
    if (target.dateType == TodoDateType.repeat) {
      print('⚠️ 반복 일정은 아직 미루기를 지원하지 않습니다.');
      return;
    }

    // 1. 화면 즉시 반영 (낙관적 업데이트)
    // 기존 가짜 ID 생성 로직을 버리고, 기존 ID 그대로 날짜만 하루 더해서 화면에 반영합니다.
    final snoozed = target.copyWith(
      date: target.date != null ? target.date!.add(const Duration(days: 1)) : null,
      rangeEnd: target.rangeEnd != null ? target.rangeEnd!.add(const Duration(days: 1)) : null,
    );

    state = state.copyWith(
      allTodos: state.allTodos.map((t) => t.id == id ? snoozed : t).toList(),
    );
    _updateDisplayedTodos();

    // 2. 서버에 미루기(T05) 전송
    final response = await AsyncValue.guard(() => _repository.snoozeTodo(id));

    // 3. 서버 업데이트 완료 후 마스터 목록 완벽 동기화
    if (!response.hasError) {
      fetchTodos();
    } else {
      // 만약 422 에러 등이 났다면 원상복구를 위해 다시 불러오기
      fetchTodos();
    }
  }
}

final todoViewModelProvider =
StateNotifierProvider.autoDispose<TodoViewModel, TodoState>((ref) {
  return TodoViewModel(ref.read(todoRepositoryProvider));
});