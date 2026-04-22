import 'package:doitdo/domain/entities/user.dart';

/// 서버 응답 `user` 필드를 받아 User 도메인 모델로 변환.
class UserDto {
  const UserDto({
    required this.id,
    required this.nickname,
    required this.email,
  });

  final int id;
  final String nickname;
  final String email;

  factory UserDto.fromJson(Map<String, dynamic> json) => UserDto(
        id: json['id'] as int,
        nickname: json['nickname'] as String,
        email: json['email'] as String,
      );

  User toEntity() => User(id: id, nickname: nickname, email: email);
}
