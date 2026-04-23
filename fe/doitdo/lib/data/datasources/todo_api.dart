import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:doitdo/core/network/api_response.dart';

part 'todo_api.g.dart';

@RestApi()
abstract class TodoApi {
  factory TodoApi(Dio dio, {String baseUrl}) = _TodoApi;

  // [T06] 일반/반복/기간 TODO 생성
  @POST('/todos')
  // ✅ Object? 대신 dynamic으로 변경! (생성기 오류 방지)
  Future<ApiResponse<dynamic>> createTodo(
      @Body() Map<String, dynamic> body,
      );
}