import 'package:doitdo/presentation/models/todo.dart';
import 'package:doitdo/data/models/todo_update_request_dto.dart';
import 'package:doitdo/data/models/todo_update_response_dto.dart';
import 'package:doitdo/data/models/todo_calendar_response_dto.dart';

abstract class TodoRepository {
  Future<void> createTodo(Todo todo);

  // 상태 변경 기능 추가
  Future<void> updateTodoStatus(String todoId, String status);

  // [추가] TODO 수정 (T04)
  Future<TodoUpdateResponseDto> updateTodo(String id, TodoUpdateRequestDto request);

  // [추가] T08: 캘린더 조회 (기간 필수, 나머지는 선택 필터)
  Future<TodoCalendarResponseDto> getCalendarTodos({
    required String from,
    required String to,
    String? status,
    String? category,
    String? type,
  });
}