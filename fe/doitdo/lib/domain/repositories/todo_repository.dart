import 'package:doitdo/presentation/models/todo.dart';
import 'package:doitdo/data/models/todo_update_request_dto.dart';
import 'package:doitdo/data/models/todo_update_response_dto.dart';
import 'package:doitdo/data/models/todo_calendar_response_dto.dart';
import 'package:doitdo/data/models/todo_list_response_dto.dart';
import 'package:doitdo/data/models/todo_detail_response_dto.dart';

abstract class TodoRepository {
  Future<TodoDetailResponseDto> createTodo(Todo todo);

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

  Future<TodoListResponseDto> getTodos({String? view, String? date});

  // TODO 상세 조회
  Future<TodoDetailResponseDto> getTodoDetail(String id);

  // TODO 삭제
  Future<void> deleteTodo(String id, {String? scope});

  // 우선순위 변경
  Future<void> updateTodoPriority(String todoId, int priority);

  // TODO 미루기
  Future<void> snoozeTodo(String todoId);


}