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
  // 체크 직후 잠깐 "주황 체크" 모습으로 노출되었다가 사라지는 todo 의 id 집합.
  // toggleTodo 가 DONE 으로 토글할 때 여기에 추가하고 ~600ms 뒤 제거 — 그 사이에는
  // _updateDisplayedTodos 가 done 필터에도 불구하고 이 항목들을 list 에 유지한다.
  final Set<String> fadingTodoIds;
  final bool pageAnimationEnabled;

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
    this.fadingTodoIds = const {},
    this.pageAnimationEnabled = true,
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
    Map<DateTime, List<Todo>>? kEvents,
    Set<String>? fadingTodoIds,
    bool? pageAnimationEnabled,
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
      fadingTodoIds: fadingTodoIds ?? this.fadingTodoIds,
      pageAnimationEnabled: pageAnimationEnabled ?? this.pageAnimationEnabled,
    );
  }
}
