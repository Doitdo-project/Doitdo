import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:doitdo/presentation/models/todo.dart';
import 'package:doitdo/presentation/pages/todo/todo_state.dart';

// 서버 통신을 위해 레포지토리와 프로바이더 파일 임포트
import 'package:doitdo/domain/repositories/todo_repository.dart';
import 'package:doitdo/presentation/providers/app_data_providers.dart';

// ✅ [추가] Request DTO 임포트 (경로는 프로젝트 구조에 맞게 수정될 수 있습니다)
import 'package:doitdo/data/models/todo_update_request_dto.dart';

class TodoViewModel extends StateNotifier<TodoState> {
  // 생성자에서 서버와 통신할 repository를 주입받도록 변경
  TodoViewModel(this._repository) : super(TodoState()){
    fetchCalendarData();
  }

  final TodoRepository _repository; // 레포지토리 저장용 변수

  // 핵심: 현재 필터(currentFilter)와 선택된 날짜에 맞춰 목록을 갱신하는 함수
  void _updateDisplayedTodos() {
    final filter = state.currentFilter;
    final selectedDay = state.selectedDay;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    List<Todo> filtered = state.allTodos;

    // 1. 기간(View) 필터 적용
    if (filter == 'upcoming') {
      filtered = filtered.where((t) => t.date != null && t.date!.isAfter(today)).toList();
    } else if (filter == 'past') {
      filtered = filtered.where((t) => t.date != null && t.date!.isBefore(today)).toList();
    } else {
      // 일반적인 경우 (all, todo, done)에는 선택된 날짜 기준
      if (selectedDay != null) {
        filtered = filtered.where((t) => t.date != null && isSameDay(t.date!, selectedDay)).toList();
      } else {
        filtered = [];
      }
    }

    // 2. 상태(Status) 필터 적용
    if (filter == 'todo') {
      filtered = filtered.where((t) => !t.isDone).toList();
    } else if (filter == 'done') {
      filtered = filtered.where((t) => t.isDone).toList();
    }

    // 3. 언제가 할 일(Someday) 필터 적용 (기간 필터는 무시하고 상태만 적용)
    List<Todo> somedayFiltered = state.allSomedayTodos;
    if (filter == 'todo') {
      somedayFiltered = somedayFiltered.where((t) => !t.isDone).toList();
    } else if (filter == 'done') {
      somedayFiltered = somedayFiltered.where((t) => t.isDone).toList();
    }

    state = state.copyWith(todos: filtered, somedayTodos: somedayFiltered);
  }

  // 필터 변경 이벤트
  void setFilter(String filter) {
    state = state.copyWith(currentFilter: filter);
    _updateDisplayedTodos();
  }

  void onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    state = state.copyWith(selectedDay: selectedDay, focusedDay: focusedDay);
    _updateDisplayedTodos();
  }

  void onFormatChanged(CalendarFormat format) {
    state = state.copyWith(calendarFormat: format);
  }

  // ── 오늘의 할 일 CRUD ───────────────────────
  void addTodo(Todo todo) {
    state = state.copyWith(allTodos: [...state.allTodos, todo]);
    _updateDisplayedTodos();
  }

  // 서버 통신 API 호출이 추가된 토글 함수!
  Future<void> toggleTodo(String id) async {
    // 1. 현재 투두 찾기
    final targetIdx = state.allTodos.indexWhere((t) => t.id == id);
    if (targetIdx == -1) return;

    // 2. 바뀔 상태 결정 (DONE ↔ TODO)
    final targetTodo = state.allTodos[targetIdx];
    final newStatus = targetTodo.isDone ? 'TODO' : 'DONE';

    // 3. 로컬 화면 먼저 재빠르게 변경 (Optimistic UI 업데이트)
    final newAll = state.allTodos.map((t) => t.id == id ? t.copyWith(isDone: !t.isDone) : t).toList();
    state = state.copyWith(allTodos: newAll);
    _updateDisplayedTodos();

    // 4. 백엔드 서버로 실제 통신 날리기! (팀 가이드라인에 따라 try-catch 대신 guard 사용)
    await AsyncValue.guard(() => _repository.updateTodoStatus(id, newStatus));
  }

  void deleteTodo(String id) {
    final newAll = state.allTodos.where((t) => t.id != id).toList();
    state = state.copyWith(allTodos: newAll);
    _updateDisplayedTodos();
  }

  // ✅ [핵심 수정] T04 API를 호출하는 비동기 updateTodo
  Future<void> updateTodo(Todo updated) async {
    // 1. 로컬 화면 먼저 빠르게 변경 (Optimistic UI)
    final newAll = state.allTodos.map((t) => t.id == updated.id ? updated : t).toList();
    state = state.copyWith(allTodos: newAll);
    _updateDisplayedTodos();

    // 2. 서버로 보낼 날짜 포맷팅 (YYYY-MM-DD 형식 맞추기)
    final startDateStr = updated.date != null
        ? updated.date!.toIso8601String().split('T')[0]
        : DateTime.now().toIso8601String().split('T')[0];

    final endDateStr = updated.rangeEnd != null
        ? updated.rangeEnd!.toIso8601String().split('T')[0]
        : null;

    // 3. Request DTO 조립
    final requestDto = TodoUpdateRequestDto(
      title: updated.title,
      // content: updated.content, // Todo 모델에 내용(content) 필드가 있다면 주석 해제하세요!
      category: updated.category.name,
      type: updated.dateType == TodoDateType.normal ? 'NORMAL' : 'PERIOD',
      startDate: startDateStr,
      endDate: endDateStr,
      // period: updated.period, // 반복 주기가 있다면 주석 해제하세요!
    );

    // 4. 백엔드 서버로 실제 수정 요청 날리기
    await AsyncValue.guard(() => _repository.updateTodo(updated.id, requestDto));
  }

  void reorderTodo(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    final List<Todo> newList = List.from(state.todos);
    final Todo item = newList.removeAt(oldIndex);
    newList.insert(newIndex, item);
    state = state.copyWith(todos: newList);
  }

  // ── 언제가 할 일 CRUD ───────────────────────
  void addSomedayTodo(Todo todo) {
    state = state.copyWith(allSomedayTodos: [...state.allSomedayTodos, todo]);
    _updateDisplayedTodos();
  }

  // 언제가 할 일도 동일하게 서버 통신 추가!
  Future<void> toggleSomedayTodo(String id) async {
    final targetIdx = state.allSomedayTodos.indexWhere((t) => t.id == id);
    if (targetIdx == -1) return;

    final targetTodo = state.allSomedayTodos[targetIdx];
    final newStatus = targetTodo.isDone ? 'TODO' : 'DONE';

    final updated = state.allSomedayTodos.map((t) => t.id == id ? t.copyWith(isDone: !t.isDone) : t).toList();
    state = state.copyWith(allSomedayTodos: updated);
    _updateDisplayedTodos();

    // 백엔드 서버로 실제 통신 날리기!
    await AsyncValue.guard(() => _repository.updateTodoStatus(id, newStatus));
  }

  void deleteSomedayTodo(String id) {
    state = state.copyWith(allSomedayTodos: state.allSomedayTodos.where((t) => t.id != id).toList());
    _updateDisplayedTodos();
  }

  // [핵심 수정] 언제가 할 일 수정 API 연동
  Future<void> updateSomedayTodo(Todo updated) async {
    // 1. 로컬 상태 변경
    final list = state.allSomedayTodos.map((t) => t.id == updated.id ? updated : t).toList();
    state = state.copyWith(allSomedayTodos: list);
    _updateDisplayedTodos();

    // 2. 서버로 보낼 임시 시작 날짜 (언제가 할 일은 날짜가 없으므로 오늘 날짜로 대체)
    final startDateStr = DateTime.now().toIso8601String().split('T')[0];

    // 3. Request DTO 조립
    final requestDto = TodoUpdateRequestDto(
      title: updated.title,
      category: updated.category.name,
      type: 'NORMAL',
      startDate: startDateStr,
    );

    // 4. 백엔드 서버로 실제 수정 요청 날리기
    await AsyncValue.guard(() => _repository.updateTodo(updated.id, requestDto));
  }

  // [추가] T08 API 호출: 캘린더 데이터 조회
  Future<void> fetchCalendarData() async {
    // 1. 현재 보고 있는 달력의 연/월을 기준으로 from, to 날짜 구하기
    final focusedDay = state.focusedDay;

    // 이번 달의 1일
    final firstDay = DateTime(focusedDay.year, focusedDay.month, 1);
    // 이번 달의 마지막 날 (다음 달 1일에서 하루 뺌)
    final lastDay = DateTime(focusedDay.year, focusedDay.month + 1, 0);

    final fromStr = firstDay.toIso8601String().split('T')[0];
    final toStr = lastDay.toIso8601String().split('T')[0];

    // 2. 백엔드 통신
    // 필터(상태, 카테고리 등)가 필요하다면 state에서 읽어와 파라미터로 넘길 수 있습니다.
    final result = await AsyncValue.guard(
          () => _repository.getCalendarTodos(from: fromStr, to: toStr),
    );

    if (result.hasValue) {
      print('📅 캘린더 조회 성공! 받아온 데이터 개수: ${result.value?.selectedDateItems.length}');
    } else if (result.hasError) {
      // ✅ 에러가 났다면 앱을 끄지 말고 조용히 로그만 남깁니다.
      print('❌ 캘린더 조회 실패: ${result.error}');
    }    // 프론트엔드의 state.allTodos 와 달력 마커 상태에 맞게 변환해서 넣어주어야 합니다.
    // 임시로 디버그 로그만 찍어볼 수 있습니다.
    // print('조회 완료! 일정 개수: ${result?.selectedDateItems.length}');
  }

  void reorderSomedayTodo(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    final List<Todo> newList = List.from(state.somedayTodos);
    final Todo item = newList.removeAt(oldIndex);
    newList.insert(newIndex, item);
    state = state.copyWith(somedayTodos: newList);
  }

  // ── 미루기 (Snooze) API ───────────────────────
  void snoozeTodo(String id) {
    final targetIdx = state.allTodos.indexWhere((t) => t.id == id);
    if (targetIdx == -1) return;
    final target = state.allTodos[targetIdx];
    if (target.isDone) return;

    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final newTodoId = DateTime.now().millisecondsSinceEpoch.toString();
    final snoozedTodo = target.copyWith(
      id: newTodoId, date: tomorrow, dateType: TodoDateType.normal,
      rangeStart: null, rangeEnd: null, repeatType: null,
      repeatStartDate: null, repeatEndDate: null,
    );

    final newAll = state.allTodos.where((t) => t.id != id).toList();
    newAll.add(snoozedTodo);
    state = state.copyWith(allTodos: newAll);
    _updateDisplayedTodos();
  }

  // ── 더미 데이터 로드 ─────────────────────────────
  void loadDummyTodos() {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final tomorrow = today.add(const Duration(days: 1));
    final day21 = DateTime(today.year, today.month, 21);

    final allTodos = [
      Todo(id: '1', title: '아침 명상 10분 하기', category: const TodoCategory(name: '건강', colorKey: CategoryColorKey.health), isDone: true, date: today),
      Todo(id: '2', title: '플러터 공부 2시간', category: const TodoCategory(name: '공부', colorKey: CategoryColorKey.study), isDone: false, date: today),
      Todo(id: '3', title: '헬스장 1시간', category: const TodoCategory(name: '운동', colorKey: CategoryColorKey.exercise), isDone: false, date: today),
      Todo(id: '4', title: '어제 했던 일 복습', category: const TodoCategory(name: '공부', colorKey: CategoryColorKey.study), isDone: true, date: yesterday),
      Todo(id: '5', title: '내일 발표 준비', category: const TodoCategory(name: '업무', colorKey: CategoryColorKey.work), isDone: false, date: tomorrow),
      Todo(id: '21_1', title: '코드 리팩토링', category: const TodoCategory(name: '업무', colorKey: CategoryColorKey.work), isDone: true, date: day21),
    ];

    final allSomeday = [
      const Todo(id: 's1', title: '도서관 책 반납하기', category: TodoCategory(name: '업무', colorKey: CategoryColorKey.work), isDone: false),
      const Todo(id: 's2', title: '운동화 새로 구매하기', category: TodoCategory(name: '취미', colorKey: CategoryColorKey.hobby), isDone: false),
    ];

    state = state.copyWith(
      allTodos: allTodos,
      allSomedayTodos: allSomeday,
      selectedDay: today,
      focusedDay: today,
    );
    _updateDisplayedTodos();
  }
}

// Provider가 생성될 때 repository를 주입해서 넘겨주도록 변경!
final todoViewModelProvider = StateNotifierProvider.autoDispose<TodoViewModel, TodoState>((ref) {
  final repository = ref.read(todoRepositoryProvider);
  return TodoViewModel(repository);
});