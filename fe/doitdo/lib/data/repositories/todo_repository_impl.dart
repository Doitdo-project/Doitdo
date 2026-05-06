import 'package:dio/dio.dart';
import 'package:doitdo/core/errors/exceptions.dart';
import 'package:doitdo/core/network/base_repository.dart';
import 'package:doitdo/core/network/dio_error_mapper.dart';
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
  Future<TodoDetailResponseDto> createTodo(Todo todo) async {
    // ✏️ 수정: dateType 에 맞는 startDate 선택
    DateTime? startDateObj;
    switch (todo.dateType) {
      case TodoDateType.normal:
        startDateObj = todo.date;
      case TodoDateType.someday:
        startDateObj = null;
      case TodoDateType.range:
        startDateObj = todo.rangeStart;
      case TodoDateType.repeat:
        startDateObj = todo.repeatStartDate;
        // ✅ [핵심 수정] 매주 반복 + repeatDays 있으면
        //    startDate 를 선택 요일 중 repeatStartDate 이후 첫 번째 날로 조정
        //    이렇게 해야 서버에서 재조회 시 start.weekday 폴백이 올바른 요일을 가리킴
        if (todo.repeatDays != null &&
            todo.repeatDays!.isNotEmpty &&
            todo.repeatStartDate != null) {
          for (int i = 0; i <= 6; i++) {
            final candidate = todo.repeatStartDate!.add(Duration(days: i));
            final flutterWd = candidate.weekday; // 1=월~7=일
            final appIdx    = flutterWd == 7 ? 0 : flutterWd; // 일→0
            if (todo.repeatDays!.contains(appIdx)) {
              startDateObj = candidate;
              break;
            }
          }
        }
    }

    final startDateStr = startDateObj?.toIso8601String().split('T')[0];

    final endDateStr = todo.rangeEnd?.toIso8601String().split('T')[0] ??
        todo.repeatEndDate?.toIso8601String().split('T')[0];

    // ✏️ 수정: period → daysOfWeek (MON,TUE,... 형식으로 변환)
    Set<String>? daysOfWeekSet;
    if (todo.dateType == TodoDateType.repeat && todo.repeatDays != null && todo.repeatDays!.isNotEmpty) {
      const dayCodeMap = {0: 'SUN', 1: 'MON', 2: 'TUE', 3: 'WED', 4: 'THU', 5: 'FRI', 6: 'SAT'};
      daysOfWeekSet = todo.repeatDays!.map((i) => dayCodeMap[i]!).toSet();
    }

    String? formattedAlertTime;
    if (todo.alarmEnabled && todo.alarmTime != null) {
      final h = todo.alarmTime!.hour.toString().padLeft(2, '0');
      final m = todo.alarmTime!.minute.toString().padLeft(2, '0');
      formattedAlertTime = "$h:$m";
    }

    final body = {
      'title': todo.title,
      'content': todo.memo,
      'category': todo.category.name,
      'type': switch (todo.dateType) {
        TodoDateType.normal => 'NORMAL',
        TodoDateType.someday => 'SOMEDAY',
        TodoDateType.range  => 'PERIOD',
        TodoDateType.repeat => 'RECURRING',
      },
      'startDate': startDateStr,
      if (endDateStr != null) 'endDate': endDateStr,
      if (daysOfWeekSet != null) 'daysOfWeek': daysOfWeekSet.toList(), // ✏️ period 대신 daysOfWeek
      if (formattedAlertTime != null) 'alertTime': formattedAlertTime,
    };

    // POST 응답의 data 필드를 TodoDetailResponseDto 로 파싱해 반환한다.
    // TodoApi.createTodo 가 ApiResponse<dynamic> 을 반환하므로
    // data 를 Map<String, dynamic> 으로 캐스팅 후 fromJson 호출.
    try {
      final response = await _todoApi.createTodo(body);
      if (!response.isSuccess) {
        throw ServerException(response.message, statusCode: response.status);
      }
      final rawData = response.data;
      if (rawData == null) {
        throw const ServerException('TODO 생성 응답에 data 가 없습니다.');
      }
      return TodoDetailResponseDto.fromJson(rawData as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
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
