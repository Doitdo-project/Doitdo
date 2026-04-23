import 'package:doitdo/domain/entities/user.dart';

/// 백엔드 `user` 객체를 받아 [User] 도메인 모델로 변환.
///
/// 스펙(`{userId, username, email}`) 과 필드명 1:1 매칭. 변경 시 [fromJson] 만 수정.
class UserDto {
  const UserDto({
    required this.userId,
    required this.username,
    required this.email,
  });

  final int userId;
  final String username;
  final String email;

  factory UserDto.fromJson(Map<String, dynamic> json) => UserDto(
        userId: (json['userId'] as num).toInt(),
        username: json['username'] as String,
        email: json['email'] as String,
      );

  User toEntity() =>
      User(userId: userId, username: username, email: email);
}
