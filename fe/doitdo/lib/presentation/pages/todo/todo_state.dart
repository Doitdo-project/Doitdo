import 'package:table_calendar/table_calendar.dart';
import 'package:doitdo/presentation/models/todo.dart';

class TodoState {
  final List<Todo> allTodos;         // 날짜가 있는 모든 할 일 원본
  final List<Todo> todos;            // 현재 화면에 표시되는 (필터링된) 할 일
  final List<Todo> allSomedayTodos;  // 언제가 할 일 원본 (새로 추가)
  final List<Todo> somedayTodos;     // 현재 화면에 표시되는 언제가 할 일
  final DateTime? selectedDay;
  final DateTime focusedDay;
  final CalendarFormat calendarFormat;
  final String currentFilter;        // 필터 상태 ('all', 'todo', 'done', 'upcoming', 'past')

  TodoState({
    this.allTodos = const [],
    this.todos = const [],
    this.allSomedayTodos = const [],
    this.somedayTodos = const [],
    this.selectedDay,
    DateTime? focusedDay,
    this.calendarFormat = CalendarFormat.month,
    this.currentFilter = 'all',
  }) : focusedDay = focusedDay ?? DateTime.now();

  TodoState copyWith({
    List<Todo>? allTodos,
    List<Todo>? todos,
    List<Todo>? allSomedayTodos,
    List<Todo>? somedayTodos,
    DateTime? selectedDay,
    DateTime? focusedDay,
    CalendarFormat? calendarFormat,
    String? currentFilter,
  }) {
    return TodoState(
      allTodos: allTodos ?? this.allTodos,
      todos: todos ?? this.todos,
      allSomedayTodos: allSomedayTodos ?? this.allSomedayTodos,
      somedayTodos: somedayTodos ?? this.somedayTodos,
      selectedDay: selectedDay ?? this.selectedDay,
      focusedDay: focusedDay ?? this.focusedDay,
      calendarFormat: calendarFormat ?? this.calendarFormat,
      currentFilter: currentFilter ?? this.currentFilter,
    );
  }
}