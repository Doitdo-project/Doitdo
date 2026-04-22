import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:doitdo/core/network/api_response.dart';

part 'todo_api.g.dart';

// ✅ 해결책: 코드 생성기가 기절하지 않도록, 응답을 받을 '빈 그릇'을 하나 만들어줍니다.
class TodoResponseDto {
  TodoResponseDto();

  // 생성기가 이 fromJson을 보고 안심하고 코드를 만들어냅니다!
  factory TodoResponseDto.fromJson(Map<String, dynamic> json) => TodoResponseDto();
}

@RestApi()
abstract class TodoApi {
  factory TodoApi(Dio dio, {String baseUrl}) = _TodoApi;

  // [T06] 일반/반복/기간 TODO 생성
  @POST('/todos')
  // ✅ dynamic 대신 우리가 방금 만든 TodoResponseDto 를 넣어줍니다.
  Future<ApiResponse<TodoResponseDto>> createTodo(
      @Body() Map<String, dynamic> body,
      );
}