import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:doitdo/presentation/models/todo.dart';
import 'package:doitdo/presentation/pages/todo/todo_state.dart';

class TodoViewModel extends StateNotifier<TodoState> {
  TodoViewModel() : super(TodoState());

  // ✅ 핵심: 현재 필터(currentFilter)와 선택된 날짜에 맞춰 목록을 갱신하는 함수
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

  void toggleTodo(String id) {
    final newAll = state.allTodos.map((t) => t.id == id ? t.copyWith(isDone: !t.isDone) : t).toList();
    state = state.copyWith(allTodos: newAll);
    _updateDisplayedTodos();
  }

  void deleteTodo(String id) {
    final newAll = state.allTodos.where((t) => t.id != id).toList();
    state = state.copyWith(allTodos: newAll);
    _updateDisplayedTodos();
  }

  void updateTodo(Todo updated) {
    final newAll = state.allTodos.map((t) => t.id == updated.id ? updated : t).toList();
    state = state.copyWith(allTodos: newAll);
    _updateDisplayedTodos();
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

  void toggleSomedayTodo(String id) {
    final updated = state.allSomedayTodos.map((t) => t.id == id ? t.copyWith(isDone: !t.isDone) : t).toList();
    state = state.copyWith(allSomedayTodos: updated);
    _updateDisplayedTodos();
  }

  void deleteSomedayTodo(String id) {
    state = state.copyWith(allSomedayTodos: state.allSomedayTodos.where((t) => t.id != id).toList());
    _updateDisplayedTodos();
  }

  void updateSomedayTodo(Todo updated) {
    final list = state.allSomedayTodos.map((t) => t.id == updated.id ? updated : t).toList();
    state = state.copyWith(allSomedayTodos: list);
    _updateDisplayedTodos();
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

final todoViewModelProvider = StateNotifierProvider.autoDispose<TodoViewModel, TodoState>((ref) => TodoViewModel());