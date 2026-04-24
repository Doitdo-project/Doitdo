import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'package:doitdo/core/network/api_response.dart';
import 'package:doitdo/data/models/todo_status_response_dto.dart';
import 'package:doitdo/data/models/todo_update_request_dto.dart';
import 'package:doitdo/data/models/todo_update_response_dto.dart';
import 'package:doitdo/data/models/todo_calendar_response_dto.dart';
import 'package:doitdo/data/models/todo_list_response_dto.dart';
import 'package:doitdo/data/models/todo_detail_response_dto.dart';
import 'package:doitdo/data/models/todo_priority_response_dto.dart';
import 'package:doitdo/data/models/todo_snooze_response_dto.dart';

part 'todo_api.g.dart';

@RestApi()
abstract class TodoApi {
  factory TodoApi(Dio dio, {String baseUrl}) = _TodoApi;

  // [수정] /todos -> /api/todos 로 변경
  @POST('/api/todos')
  Future<ApiResponse<dynamic>> createTodo(
      @Body() Map<String, dynamic> body,
      );

  // [수정] /todos -> /api/todos 로 변경
  @PATCH('/api/todos/{todoId}/status')
  Future<ApiResponse<dynamic>> changeTodoStatus(
      @Path('todoId') int todoId,
      @Body() Map<String, dynamic> body,
      );

  // [수정] /todos -> /api/todos 로 변경
  @PATCH('/api/todos/{todoId}')
  Future<ApiResponse<TodoUpdateResponseDto>> updateTodo(
      @Path('todoId') int todoId,
      @Body() TodoUpdateRequestDto request,
      );

  // [수정] /todos -> /api/todos 로 변경
  @GET('/api/todos/calendar')
  Future<ApiResponse<TodoCalendarResponseDto>> getCalendar(
      @Query('from') String from,
      @Query('to') String to,
      @Query('status') String? status,
      @Query('category') String? category,
      @Query('type') String? type,
      );

  // [T02] TODO 목록 조회
  @GET('/api/todos')
  Future<ApiResponse<TodoListResponseDto>> getTodoList({
    @Query('view') String? view,
    @Query('status') String? status,
    @Query('category') String? category,
    @Query('type') String? type,
    @Query('date') String? date,
    @Query('q') String? q,
    @Query('sort') String? sort,
  });

  // TODO 상세 조회
  @GET('/api/todos/{todoId}')
  Future<ApiResponse<TodoDetailResponseDto>> getTodoDetail(
      @Path('todoId') int todoId,
      );

  // TODO 삭제
  @DELETE('/api/todos/{todoId}')
  Future<void> deleteTodo(
      @Path('todoId') int todoId,
      @Query('scope') String? scope,
      );

  // TODO 우선순위 변경
  @PATCH('/api/todos/{todoId}/priority')
  Future<ApiResponse<TodoPriorityResponseDto>> updateTodoPriority(
      @Path('todoId') int todoId,
      @Body() Map<String, dynamic> body,
      );

  // TODO 미루기
  @POST('/api/todos/{todoId}/snooze')
  Future<ApiResponse<TodoSnoozeResponseDto>> snoozeTodo(
      @Path('todoId') int todoId,
      );
}