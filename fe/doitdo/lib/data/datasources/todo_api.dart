import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'package:doitdo/core/network/api_response.dart';
import 'package:doitdo/data/models/todo_status_response_dto.dart';

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
}