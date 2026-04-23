import 'package:doitdo/core/network/base_repository.dart';
import 'package:doitdo/data/datasources/todo_api.dart';
import 'package:doitdo/domain/repositories/todo_repository.dart';
import 'package:doitdo/presentation/models/todo.dart';

import 'package:doitdo/data/models/todo_calendar_response_dto.dart';
import 'package:doitdo/data/models/todo_update_request_dto.dart';
import 'package:doitdo/data/models/todo_update_response_dto.dart';
import 'package:doitdo/core/network/api_response.dart'; // ApiResponse 타입을 명확히 하기 위해 추가

class TodoRepositoryImpl extends BaseRepository implements TodoRepository {
  TodoRepositoryImpl(this._todoApi);

  final TodoApi _todoApi;

  @override
  Future<void> createTodo(Todo todo) async {
    final startDateStr = todo.date?.toIso8601String().split('T')[0] ??
        DateTime.now().toIso8601String().split('T')[0];
    final endDateStr = todo.rangeEnd?.toIso8601String().split('T')[0] ??
        todo.repeatEndDate?.toIso8601String().split('T')[0];

    int? periodDays;
    if (todo.dateType == TodoDateType.repeat) {
      if (todo.repeatType == '매주') {
        periodDays = 7;
      } else if (todo.repeatType == '매월') {
        periodDays = 30;
      } else if (todo.repeatType == '매년') {
        periodDays = 365;
      }
    }

    final body = {
      'title': todo.title,
      'content': todo.memo,
      'category': todo.category.name,
      'type': todo.dateType.name.toUpperCase(),
      'startDate': startDateStr,
      if (endDateStr != null) 'endDate': endDateStr,
      if (periodDays != null) 'period': periodDays,
    };

    await safeApiCallNoData(() => _todoApi.createTodo(body));
  }

  // [T03] 상태 변경 구현
  @override
  Future<void> updateTodoStatus(String todoId, String status) async {
    final idAsInt = int.tryParse(todoId) ?? 0;
    await safeApiCall(() => _todoApi.updateTodoStatus(idAsInt, status));
  }

  // ✅ [최종 수정] T04: TODO 수정 실제 구현
  @override
  Future<TodoUpdateResponseDto> updateTodo(String id, TodoUpdateRequestDto request) async {
    // 1. String ID를 int로 변환
    final intId = int.tryParse(id) ?? 0;

    // 2. safeApiCall의 결과를 변수에 담습니다.
    // 이때 response의 타입은 TodoUpdateResponseDto가 됩니다 (ApiResponse.data가 추출됨).
    final response = await safeApiCall(
          () => _todoApi.updateTodo(intId, request),
    );

    // 3. TodoUpdateResponseDto 객체를 그대로 반환합니다.
    return response;
  }

  // [추가] T08: 캘린더 조회 실제 구현
  @override
  Future<TodoCalendarResponseDto> getCalendarTodos({
    required String from,
    required String to,
    String? status,
    String? category,
    String? type,
  }) async {
    final response = await safeApiCall(
          () => _todoApi.getCalendar(from, to, status, category, type),
    );
    return response;
  }
}