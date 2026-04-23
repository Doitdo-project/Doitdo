import 'package:doitdo/core/network/base_repository.dart';
import 'package:doitdo/data/datasources/todo_api.dart';
import 'package:doitdo/domain/repositories/todo_repository.dart';
import 'package:doitdo/presentation/models/todo.dart';

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
      if (todo.repeatType == '매주') periodDays = 7;
      else if (todo.repeatType == '매월') periodDays = 30;
      else if (todo.repeatType == '매년') periodDays = 365;
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
    // 프론트엔드의 todoId는 현재 String(시간값)이므로, 백엔드 명세서(Number)에 맞게 int로 파싱
    final idAsInt = int.tryParse(todoId) ?? 0;

    // 응답 데이터(TodoStatusResponseDto)를 파싱하기 위해 safeApiCall 사용
    await safeApiCall(() => _todoApi.updateTodoStatus(idAsInt, status));
  }
}