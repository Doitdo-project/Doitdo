import 'package:table_calendar/table_calendar.dart';
import 'package:doitdo/presentation/models/todo.dart';

class TodoState {
  final List<Todo> allTodos;
  final List<Todo> todos;
  final List<Todo> allSomedayTodos;
  final List<Todo> somedayTodos;
  final DateTime? selectedDay;
  final DateTime focusedDay;
  final CalendarFormat calendarFormat;
  final String currentFilter;
  final Map<DateTime, List<Todo>> kEvents;

  TodoState({
    this.allTodos = const [],
    this.todos = const [],
    this.allSomedayTodos = const [],
    this.somedayTodos = const [],
    this.selectedDay,
    DateTime? focusedDay,
    this.calendarFormat = CalendarFormat.month,
    this.currentFilter = 'all',
    this.kEvents = const {},
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
    // ✅ 3. copyWith 에도 kEvents 추가
    Map<DateTime, List<Todo>>? kEvents,
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
      kEvents: kEvents ?? this.kEvents,
    );
  }
}