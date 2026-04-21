import 'package:table_calendar/table_calendar.dart';
import 'package:doitdo/presentation/models/todo.dart';

class TodoState {
  TodoState({
    this.selectedDay,
    DateTime? focusedDay,
    this.calendarFormat = CalendarFormat.month,
    this.todos = const [],
    this.somedayTodos = const [],
  }) : focusedDay = focusedDay ?? DateTime.now();

  final DateTime? selectedDay;
  final DateTime focusedDay;
  final CalendarFormat calendarFormat;

  /// 선택된 날짜의 할 일 (오늘의 할 일 / X월 Y일의 할 일)
  final List<Todo> todos;

  /// 날짜 미지정 — 언제가 할 일
  final List<Todo> somedayTodos;

  TodoState copyWith({
    DateTime? selectedDay,
    DateTime? focusedDay,
    CalendarFormat? calendarFormat,
    List<Todo>? todos,
    List<Todo>? somedayTodos,
  }) {
    return TodoState(
      selectedDay: selectedDay ?? this.selectedDay,
      focusedDay: focusedDay ?? this.focusedDay,
      calendarFormat: calendarFormat ?? this.calendarFormat,
      todos: todos ?? this.todos,
      somedayTodos: somedayTodos ?? this.somedayTodos,
    );
  }
}