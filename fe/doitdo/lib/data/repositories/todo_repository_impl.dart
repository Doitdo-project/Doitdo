import 'package:doitdo/core/network/base_repository.dart';
import 'package:doitdo/data/datasources/todo_api.dart';
import 'package:doitdo/domain/repositories/todo_repository.dart';
import 'package:doitdo/presentation/models/todo.dart';

import 'package:doitdo/data/models/todo_calendar_response_dto.dart';
import 'package:doitdo/data/models/todo_update_request_dto.dart';
import 'package:doitdo/data/models/todo_update_response_dto.dart';
import 'package:doitdo/core/network/api_response.dart'; // ApiResponse 타입을 명확히 하기 위해 추가
import 'package:doitdo/data/models/todo_list_response_dto.dart';
import 'package:doitdo/data/models/todo_detail_response_dto.dart';

class TodoRepositoryImpl extends BaseRepository implements TodoRepository {
  TodoRepositoryImpl(this._todoApi);

  final TodoApi _todoApi;

  @override
  Future<void> createTodo(Todo todo) async {
    // ✏️ 수정: dateType 에 맞는 startDate 선택
    //   NORMAL   → todo.date
    //   PERIOD   → todo.rangeStart  (기존에 todo.date 를 써서 null 전송되던 버그 수정)
    //   RECURRING → todo.repeatStartDate
    final startDateStr = switch (todo.dateType) {
      TodoDateType.normal => todo.date?.toIso8601String().split('T')[0],
      TodoDateType.range  => todo.rangeStart?.toIso8601String().split('T')[0],
      TodoDateType.repeat => todo.repeatStartDate?.toIso8601String().split('T')[0],
    };

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
      // ✏️ 수정: TodoDateType → 서버 enum 매핑
      //   normal → NORMAL
      //   range  → PERIOD  (RANGE 는 서버에 없음)
      //   repeat → RECURRING
      'type': switch (todo.dateType) {
        TodoDateType.normal => 'NORMAL',
        TodoDateType.range  => 'PERIOD',
        TodoDateType.repeat => 'RECURRING',
      },
      'startDate': startDateStr, // 🔥 null이 백엔드로 무사히 넘어감
      if (endDateStr != null) 'endDate': endDateStr,
      if (periodDays != null) 'period': periodDays,
    };

    await safeApiCallNoData(() => _todoApi.createTodo(body));
  }

  // [T03] 상태 변경 구현
  @override
  Future<void> updateTodoStatus(String todoId, String status) async {
    final idAsInt = int.tryParse(todoId) ?? 0;

    await safeApiCall(() => _todoApi.changeTodoStatus(idAsInt, {'status': status}));
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

  // Todo리스트 조회
  @override
  Future<TodoListResponseDto> getTodos({String? view, String? date}) async {
    final response = await safeApiCall(
          () => _todoApi.getTodoList(view: view, date: date),
    );
    return response; // ApiResponse가 이미 벗겨진 상태라면 response 그대로 반환
  }

  // 상세 조회 실제 구현
  @override
  Future<TodoDetailResponseDto> getTodoDetail(String id) async {
    final intId = int.tryParse(id) ?? 0;
    final response = await safeApiCall(
          () => _todoApi.getTodoDetail(intId),
    );
    return response;
  }

  // TODO 삭제 구현
  @override
  Future<void> deleteTodo(String id, {String? scope}) async {
    final intId = int.tryParse(id) ?? 0;
    try {
      await _todoApi.deleteTodo(intId, scope);
    } catch (e) {
      print('삭제 통신 에러: $e'); // 에러가 나면 로그만 찍기
    }
  }

  // 우선순위 변경
  @override
  Future<void> updateTodoPriority(String todoId, int priority) async {
    final intId = int.tryParse(todoId) ?? 0;

    // Request Body에 {"priority": 1} 형태로 담아서 전송
    await safeApiCall(
            () => _todoApi.updateTodoPriority(intId, {'priority': priority})
    );
  }

  // TODO 미루기 실제 구현
  @override
  Future<void> snoozeTodo(String todoId) async {
    final intId = int.tryParse(todoId) ?? 0;
    // API 호출 (결과 데이터는 굳이 파싱하지 않고 넘깁니다)
    await safeApiCall(() => _todoApi.snoozeTodo(intId));
  }
}