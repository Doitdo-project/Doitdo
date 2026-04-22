import 'package:doitdo/data/models/user_dto.dart';
import 'package:doitdo/domain/entities/auth_tokens.dart';

/// `POST /api/auth/google` 응답 포맷.
///
/// 백엔드 응답 필드명 변경 시 [fromJson] 매핑만 고치면 됨.
/// 현재 합의된 스키마:
/// ```json
/// {
///   "accessToken": "...",
///   "refreshToken": "...",
///   "user": { "id": 1, "nickname": "...", "email": "..." }
/// }
/// ```
class AuthResponseDto {
  const AuthResponseDto({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final UserDto user;

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) => AuthResponseDto(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        user: UserDto.fromJson(json['user'] as Map<String, dynamic>),
      );

  AuthTokens get tokens =>
      AuthTokens(accessToken: accessToken, refreshToken: refreshToken);
}
