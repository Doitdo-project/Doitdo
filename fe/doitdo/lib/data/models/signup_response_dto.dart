import 'package:doitdo/data/models/user_dto.dart';
import 'package:doitdo/domain/entities/user.dart';

/// `POST /api/auth/signup` 응답 페이로드.
///
/// 스펙상 회원가입은 **토큰을 반환하지 않는다** — 가입 성공 후 별도로
/// `/api/auth/login` 을 호출해 세션을 얻어야 함.
/// 응답 data = `{userId, username, email, birthDateRegistered, agreementsAccepted}`.
///
/// 신규 가입 직후이므로 `birthDateRegistered` / `agreementsAccepted` 는 항상 false 로
/// 내려오지만, 응답 누락에 대비해 폴백을 둔다.
class SignUpResponseDto {
  const SignUpResponseDto({
    required this.userId,
    required this.username,
    required this.email,
    required this.birthDateRegistered,
    required this.agreementsAccepted,
  });

  final int userId;
  final String username;
  final String email;
  final bool birthDateRegistered;
  final bool agreementsAccepted;

  factory SignUpResponseDto.fromJson(Map<String, dynamic> json) =>
      SignUpResponseDto(
        userId: (json['userId'] as num).toInt(),
        username: json['username'] as String,
        email: json['email'] as String,
        birthDateRegistered: json['birthDateRegistered'] as bool? ?? false,
        agreementsAccepted: json['agreementsAccepted'] as bool? ?? false,
      );

  // 일반 가입(이메일+비번) 경로만 SignUp 을 거치므로 hasPassword 는 항상 true.
  User toEntity() => User(
        userId: userId,
        username: username,
        email: email,
        hasPassword: true,
        birthDateRegistered: birthDateRegistered,
        agreementsAccepted: agreementsAccepted,
      );

  /// 로그인 직후 주입될 예정이라면 UserDto 로 변환해도 된다.
  UserDto toDto() => UserDto(
        userId: userId,
        username: username,
        email: email,
        hasPassword: true,
        birthDateRegistered: birthDateRegistered,
        agreementsAccepted: agreementsAccepted,
      );
}
