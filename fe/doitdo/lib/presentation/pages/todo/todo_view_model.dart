import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:doitdo/presentation/models/todo.dart';
import 'package:doitdo/presentation/pages/todo/todo_state.dart';

class TodoViewModel extends StateNotifier<TodoState> {
  TodoViewModel() : super(TodoState());

  void onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    state = state.copyWith(
      selectedDay: selectedDay,
      focusedDay: focusedDay,
    );
    // TODO: selectedDay 기준으로 서버/로컬 DB에서 해당 날짜 할 일 필터링
  }

  void onFormatChanged(CalendarFormat format) {
    state = state.copyWith(calendarFormat: format);
  }

  // ── 오늘의 할 일 토글 ──────────────────────
  void toggleTodo(String id) {
    final updated = state.todos.map((todo) {
      return todo.id == id ? todo.copyWith(isDone: !todo.isDone) : todo;
    }).toList();
    state = state.copyWith(todos: updated);
  }

  // ── 언제가 할 일 토글 ──────────────────────
  void toggleSomedayTodo(String id) {
    final updated = state.somedayTodos.map((todo) {
      return todo.id == id ? todo.copyWith(isDone: !todo.isDone) : todo;
    }).toList();
    state = state.copyWith(somedayTodos: updated);
  }

  // ── 임시 더미 데이터 ───────────────────────
  void loadDummyTodos() {
    state = state.copyWith(
      // 오늘의 할 일 (날짜 지정)
      todos: [
        const Todo(
          id: '1',
          title: '아침 명상 10분 하기',
          category: TodoCategory(name: '건강', colorKey: CategoryColorKey.health),
          isDone: true,
        ),
        const Todo(
          id: '2',
          title: '아침 명상 10분 하기',
          category: TodoCategory(name: '건강', colorKey: CategoryColorKey.health),
          isDone: false,
        ),
        const Todo(
          id: '3',
          title: '아침 명상 10분 하기',
          category: TodoCategory(name: '건강', colorKey: CategoryColorKey.health),
          isDone: false,
        ),
      ],
      // 언제가 할 일 (날짜 미지정)
      somedayTodos: [
        const Todo(
          id: 's1',
          title: '도서관 책 반납하기',
          category: TodoCategory(name: '건강', colorKey: CategoryColorKey.health),
          isDone: false,
        ),
        const Todo(
          id: 's2',
          title: '운동화 새로 구매하기',
          category: TodoCategory(name: '건강', colorKey: CategoryColorKey.health),
          isDone: false,
        ),
      ],
    );
  }
}

final todoViewModelProvider =
StateNotifierProvider.autoDispose<TodoViewModel, TodoState>(
      (ref) => TodoViewModel(),
);