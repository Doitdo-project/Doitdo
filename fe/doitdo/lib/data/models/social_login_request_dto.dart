/// `POST /api/auth/social/{provider}` 요청 바디.
///
/// - `accessToken` — Google/Kakao SDK 의 OAuth access token, Apple 은 identityToken(JWT).
/// - `appleAuthorizationCode` — **APPLE provider 전용**(다른 provider 에선 null).
///   Apple SDK 가 함께 내려주는 1회용 코드로, 서버가 Apple `/auth/token` 에 교환해
///   refresh_token 을 받아 저장한다. 회원탈퇴 시 Apple `/auth/revoke` 호출에 사용 →
///   App Store 정책 5.1.1(v) + Apple Developer 가이드 충족.
///
/// 백엔드는 APPLE 호출에서 이 필드가 비어 있으면 `A03-002` 로 거절한다.
class SocialLoginRequestDto {
  const SocialLoginRequestDto({
    required this.accessToken,
    this.appleAuthorizationCode,
  });

  final String accessToken;
  final String? appleAuthorizationCode;

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        if (appleAuthorizationCode != null)
          'appleAuthorizationCode': appleAuthorizationCode,
      };
}
