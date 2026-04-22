import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'package:doitdo/core/network/api_response.dart';
import 'package:doitdo/data/models/check_email_response_dto.dart';

part 'user_api.g.dart';

/// `/api/users/*` 엔드포인트 그룹.
///
/// Retrofit 이 [UserApi] 구현체(`_UserApi`)를 코드젠으로 만들어준다.
/// 새 엔드포인트 추가 후에는 반드시:
///   dart run build_runner build --delete-conflicting-outputs
///
/// 응답 envelope(`{status, message, data}`) 은 [ApiResponse] 로 감싸고
/// RepositoryImpl 의 `safeApiCall` 이 벗겨낸다.
@RestApi()
abstract class UserApi {
  factory UserApi(Dio dio, {String baseUrl}) = _UserApi;

  /// 이메일 중복 확인. `data.available == true` 면 가입 가능.
  @GET('/api/users/check-email')
  Future<ApiResponse<CheckEmailResponseDto>> checkEmail(
    @Query('email') String email,
  );
}