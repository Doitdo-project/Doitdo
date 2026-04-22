import 'package:dio/dio.dart';

import 'package:doitdo/data/models/auth_response_dto.dart';

/// 우리 백엔드 `/auth/*` 엔드포인트 호출 전담.
///
/// 외부 OAuth 제공자(Google/Kakao/Apple) 와의 통신은 각 SDK 가 처리하고,
/// 여기서는 SDK 가 돌려준 accessToken 을 서버에 넘기는 단계만 담당한다.
///
/// 소셜 로그인 통합 엔드포인트:
///   POST /auth/social/{provider}
///   provider: GOOGLE | KAKAO
///   body: { "accessToken": "..." }
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio);

  final Dio _dio;

  /// Google access token 을 서버로 보내고 우리 서비스 세션을 발급받는다.
  /// 서버는 받은 토큰으로 Google userinfo API 를 호출해 유저 정보를 검증.
  Future<AuthResponseDto> loginWithGoogle({required String accessToken}) {
    return _loginWithSocial(provider: 'GOOGLE', accessToken: accessToken);
  }

  /// Kakao access token 을 서버로 보내고 우리 서비스 세션을 발급받는다.
  /// 서버는 Kakao `/v2/user/me` 로 유저 정보 조회.
  Future<AuthResponseDto> loginWithKakao({required String accessToken}) {
    return _loginWithSocial(provider: 'KAKAO', accessToken: accessToken);
  }

  Future<AuthResponseDto> _loginWithSocial({
    required String provider,
    required String accessToken,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/social/$provider',
      data: {'accessToken': accessToken},
    );
    return AuthResponseDto.fromJson(response.data!);
  }

  /// 서버 세션 종료. 실패해도 로컬 정리는 Repository 레이어에서 진행됨.
  Future<void> logout() async {
    await _dio.post<void>('/auth/logout');
  }
}
