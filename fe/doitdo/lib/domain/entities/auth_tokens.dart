/// 우리 서비스 세션 토큰 쌍.
///
/// [accessToken] 은 API 호출 시 Authorization 헤더에 실리고,
/// [refreshToken] 은 access 만료 시 /auth/refresh 로 재발급용.
///
/// secure_storage (iOS Keychain / Android EncryptedSharedPreferences) 에 저장한다.
/// SharedPreferences 에 두지 말 것 — 평문 저장이라 루팅된 기기에서 유출 위험.
class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
  });

  final String accessToken;
  final String refreshToken;
}
