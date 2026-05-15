import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'package:doitdo/core/network/api_response.dart';
import 'package:doitdo/data/models/auth_response_dto.dart';
import 'package:doitdo/data/models/empty_data_dto.dart';
import 'package:doitdo/data/models/login_request_dto.dart';
import 'package:doitdo/data/models/password_reset_confirm_request_dto.dart';
import 'package:doitdo/data/models/password_reset_request_dto.dart';
import 'package:doitdo/data/models/password_reset_verify_request_dto.dart';
import 'package:doitdo/data/models/password_reset_verify_response_dto.dart';
import 'package:doitdo/data/models/refresh_request_dto.dart';
import 'package:doitdo/data/models/signup_request_dto.dart';
import 'package:doitdo/data/models/signup_response_dto.dart';
import 'package:doitdo/data/models/social_login_request_dto.dart';
import 'package:doitdo/data/models/token_pair_dto.dart';

part 'auth_api.g.dart';

/// `/api/auth/*` 엔드포인트 그룹.
///
/// 응답은 전부 [ApiResponse] envelope 으로 감싸서 `safeApiCall` 이 벗겨낸다.
/// 새 엔드포인트 추가 시에는:
///   dart run build_runner build --delete-conflicting-outputs
///
/// ### 엔드포인트별 인증 토큰 필요 여부
/// - **login / signup / refresh / social / password reset 3단계** → 토큰 없이 호출
///   (Dio 인터셉터에서 제외 대상)
/// - **logout** → Bearer 토큰 필요 (access token 주입)
@RestApi()
abstract class AuthApi {
  factory AuthApi(Dio dio, {String baseUrl}) = _AuthApi;

  /// 아이디(username) + 비밀번호 로그인.
  @POST('/api/auth/login')
  Future<ApiResponse<AuthResponseDto>> login(
    @Body() LoginRequestDto body,
  );

  /// 이메일 + 닉네임 + 비밀번호로 회원가입.
  /// 가입 성공 시 토큰은 **발급되지 않음** — 후속으로 login 호출 필요.
  @POST('/api/auth/signup')
  Future<ApiResponse<SignUpResponseDto>> signUp(
    @Body() SignUpRequestDto body,
  );

  /// 소셜 로그인. [provider] = "GOOGLE" | "KAKAO" | "APPLE" (대문자).
  /// body 의 accessToken 은 각 SDK 에서 발급받은 OAuth 토큰
  /// (Google idToken / Kakao accessToken / Apple identityToken).
  /// APPLE 의 경우 [SocialLoginRequestDto.appleAuthorizationCode] 도 함께 전송 필수.
  @POST('/api/auth/social/{provider}')
  Future<ApiResponse<AuthResponseDto>> socialLogin(
    @Path('provider') String provider,
    @Body() SocialLoginRequestDto body,
  );

  /// refresh token 으로 토큰 쌍 재발급. user 정보는 반환하지 않음.
  @POST('/api/auth/refresh')
  Future<ApiResponse<TokenPairDto>> refresh(
    @Body() RefreshRequestDto body,
  );

  /// 로그아웃 — refresh token 무효화. DELETE 메서드, 바디 없음.
  /// 호출 시 Authorization: Bearer access_token 이 자동 주입된다.
  /// 응답 `data` 는 빈 객체(`{}`) 라서 [EmptyDataDto] placeholder 로 받는다.
  @DELETE('/api/auth/logout')
  Future<ApiResponse<EmptyDataDto>> logout();

  // ── 비밀번호 재설정 (3단계 플로우, 모두 비로그인 상태에서 호출) ─────────

  /// 1단계 — 가입된 이메일로 인증번호(OTP) 발송 요청.
  /// 보안상 미가입 이메일에도 동일 응답을 내려줄 수 있으므로(스펙 확정 시 갱신)
  /// 호출측은 성공 여부만으로 가입 여부를 추정하지 않는다.
  @POST('/api/auth/password/reset-request')
  Future<ApiResponse<EmptyDataDto>> requestPasswordReset(
    @Body() PasswordResetRequestDto body,
  );

  /// 2단계 — 이메일로 받은 인증번호 검증. 성공 시 1회용 `resetToken` 발급.
  /// 이 토큰을 3단계 호출 바디로 그대로 넘긴다.
  @POST('/api/auth/password/reset/verify-code')
  Future<ApiResponse<PasswordResetVerifyResponseDto>> verifyPasswordResetCode(
    @Body() PasswordResetVerifyRequestDto body,
  );

  /// 3단계 — `resetToken` + 새 비밀번호로 실제 비밀번호 갱신.
  /// 성공 후에도 자동 로그인은 되지 않으므로 호출측이 로그인 화면으로 유도해야 한다.
  @POST('/api/auth/password/reset')
  Future<ApiResponse<EmptyDataDto>> confirmPasswordReset(
    @Body() PasswordResetConfirmRequestDto body,
  );
}
