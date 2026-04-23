import 'package:doitdo/data/models/user_dto.dart';
import 'package:doitdo/domain/entities/auth_tokens.dart';

/// 로그인 / 소셜 로그인 공통 응답 페이로드.
///
/// 스펙:
/// - `POST /api/auth/login` 응답 data
/// - `POST /api/auth/social/{provider}` 응답 data (소셜은 `isNewUser` 추가 포함)
///
/// ```json
/// {
///   "accessToken": "...",
///   "refreshToken": "...",
///   "user": { "userId": 1, "username": "...", "email": "..." },
///   "isNewUser": true   // 소셜 로그인에만 존재
/// }
/// ```
class AuthResponseDto {
  const AuthResponseDto({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    this.isNewUser,
  });

  final String accessToken;
  final String refreshToken;
  final UserDto user;

  /// 소셜 로그인 응답에만 실리는 "첫 로그인" 플래그. 일반 로그인은 null.
  final bool? isNewUser;

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) =>
      AuthResponseDto(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        user: UserDto.fromJson(json['user'] as Map<String, dynamic>),
        isNewUser: json['isNewUser'] as bool?,
      );

  AuthTokens get tokens =>
      AuthTokens(accessToken: accessToken, refreshToken: refreshToken);
}
