import 'package:doitdo/domain/entities/user.dart';

/// 백엔드 `user` 객체를 받아 [User] 도메인 모델로 변환.
///
/// 스펙(`{userId, username, email, hasPassword}`) 과 필드명 1:1 매칭. 변경 시 [fromJson] 만 수정.
///
/// `hasPassword` 는 서버가 응답에 항상 포함해주는 플래그 (소셜 전용 가입자면 false).
/// 구버전 응답과의 호환을 위해 누락 시 false 로 폴백 — 기능적으로 더 보수적인(=비번 변경 숨김) 쪽.
class UserDto {
  const UserDto({
    required this.userId,
    required this.username,
    required this.email,
    required this.hasPassword,
  });

  final int userId;
  final String username;
  final String email;
  final bool hasPassword;

  factory UserDto.fromJson(Map<String, dynamic> json) => UserDto(
        userId: (json['userId'] as num).toInt(),
        username: json['username'] as String,
        email: json['email'] as String,
        hasPassword: json['hasPassword'] as bool? ?? false,
      );

  User toEntity() => User(
        userId: userId,
        username: username,
        email: email,
        hasPassword: hasPassword,
      );
}
