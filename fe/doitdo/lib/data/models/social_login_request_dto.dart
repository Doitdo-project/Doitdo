/// `POST /api/auth/social/{provider}` 요청 바디.
///
/// 스펙: `{accessToken}` — Google/Kakao SDK 에서 발급받은 OAuth access token.
/// 백엔드가 이 토큰으로 provider 의 userinfo 를 조회 → 검증 → 세션 발급.
class SocialLoginRequestDto {
  const SocialLoginRequestDto({required this.accessToken});

  final String accessToken;

  Map<String, dynamic> toJson() => {'accessToken': accessToken};
}
