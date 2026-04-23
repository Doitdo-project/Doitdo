import 'package:doitdo/domain/entities/auth_tokens.dart';

/// `POST /api/auth/refresh` 응답 페이로드.
///
/// user 정보 없이 토큰 한 쌍만 돌려준다.
/// ```json
/// { "accessToken": "...", "refreshToken": "..." }
/// ```
class TokenPairDto {
  const TokenPairDto({
    required this.accessToken,
    required this.refreshToken,
  });

  final String accessToken;
  final String refreshToken;

  factory TokenPairDto.fromJson(Map<String, dynamic> json) => TokenPairDto(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
      );

  AuthTokens toEntity() =>
      AuthTokens(accessToken: accessToken, refreshToken: refreshToken);
}
