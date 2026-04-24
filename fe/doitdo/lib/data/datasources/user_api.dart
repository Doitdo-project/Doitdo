import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'package:doitdo/core/network/api_response.dart';
import 'package:doitdo/data/models/change_password_request_dto.dart';
import 'package:doitdo/data/models/check_email_response_dto.dart';
import 'package:doitdo/data/models/check_username_response_dto.dart';
import 'package:doitdo/data/models/empty_data_dto.dart';
import 'package:doitdo/data/models/user_dto.dart';

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

  /// 내 정보 조회. 로그인된 사용자의 최신 `{userId, username, email}` 을 반환.
  /// 인증 필요(Bearer). `AuthInterceptor` 가 자동 주입.
  @GET('/api/users/me')
  Future<ApiResponse<UserDto>> getMe();

  /// 비밀번호 변경. 성공 시 204 No Content — 응답 본문이 없으므로 [EmptyDataDto].
  /// 실패(현재 비밀번호 불일치 등) 는 `ServerException(message)` 으로 떨어진다.
  @POST('/api/users/me/password')
  Future<ApiResponse<EmptyDataDto>> changePassword(
    @Body() ChangePasswordRequestDto body,
  );

  /// 이메일 중복 확인. `data.available == true` 면 가입 가능.
  @GET('/api/users/check-email')
  Future<ApiResponse<CheckEmailResponseDto>> checkEmail(
    @Query('email') String email,
  );

  /// 닉네임(username) 중복 확인. `data.available == true` 면 가입 가능.
  @GET('/api/users/check-username')
  Future<ApiResponse<CheckUsernameResponseDto>> checkUsername(
    @Query('username') String username,
  );
}
