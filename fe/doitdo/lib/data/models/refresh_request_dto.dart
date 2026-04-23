/// `POST /api/auth/refresh` 요청 바디.
///
/// 스펙: `{refreshToken}` — access 만료 시 이 엔드포인트로 재발급 받음.
class RefreshRequestDto {
  const RefreshRequestDto({required this.refreshToken});

  final String refreshToken;

  Map<String, dynamic> toJson() => {'refreshToken': refreshToken};
}
