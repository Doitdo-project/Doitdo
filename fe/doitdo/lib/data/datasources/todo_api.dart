import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'package:doitdo/core/network/api_response.dart';
import 'package:doitdo/data/models/todo_status_response_dto.dart';
import 'package:doitdo/data/models/todo_update_request_dto.dart';
import 'package:doitdo/data/models/todo_update_response_dto.dart';
import 'package:doitdo/data/models/todo_calendar_response_dto.dart';

part 'todo_api.g.dart';


@RestApi()
abstract class TodoApi {
  factory TodoApi(Dio dio, {String baseUrl}) = _TodoApi;

  // [T06] 일반/반복/기간 TODO 생성
  @POST('/todos')
  Future<ApiResponse<dynamic>> createTodo(
      @Body() Map<String, dynamic> body,
      );

  // [T03] TODO 상태 변경 (추가)
  // URL: /todos/{todoId}/status?status=DONE
  @PATCH('/todos/{todoId}/status')
  Future<ApiResponse<TodoStatusResponseDto>> updateTodoStatus(
      @Path('todoId') int todoId,
      @Query('status') String status,
      );

  // [수정 완료] T04: TODO 수정
  // 1. {todoId}와 @Path('todoId') 이름을 일치시킴
  // 2. ID 타입을 int로 변경하여 서버 스펙 준수
  // 3. ApiResponse로 다시 감싸서 safeApiCall과의 호환성 해결
  @PATCH('/todos/{todoId}')
  Future<ApiResponse<TodoUpdateResponseDto>> updateTodo(
      @Path('todoId') int todoId,
      @Body() TodoUpdateRequestDto request,
      );

  // [추가] T08: TODO 캘린더 조회
  @GET('/todos/calendar')
  Future<ApiResponse<TodoCalendarResponseDto>> getCalendar(
      @Query('from') String from,
      @Query('to') String to,
      @Query('status') String? status,
      @Query('category') String? category,
      @Query('type') String? type,
      );
}