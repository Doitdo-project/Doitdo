import 'package:doitdo/domain/entities/user.dart';

/// 백엔드 `user` 객체를 받아 [User] 도메인 모델로 변환.
///
/// 스펙(`UserInfoResp`) 과 필드명 1:1 매칭. 변경 시 [fromJson] 만 수정.
///
/// `hasPassword` 는 서버가 응답에 항상 포함해주는 플래그 (소셜 전용 가입자면 false).
/// 구버전 응답과의 호환을 위해 누락 시 false 로 폴백 — 기능적으로 더 보수적인(=비번 변경 숨김) 쪽.
///
/// `birthDateRegistered` / `agreementsAccepted` 는 첫 로그인 시 온보딩 분기에 사용.
/// 서버가 항상 내려주지만 누락에 대비해 false 로 폴백 (= 온보딩 다시 노출).
///
/// `dailyAttendanceClaimed` 는 오늘 자동 출석 보상이 지급됐는지. BE 가 점진적으로
/// 배포 중이라 누락될 수 있으니 default true (= 알림 안 띄움) 폴백 — 잘못된 알림
/// 발화를 막는 게 누락된 알림보다 안전하다.
class UserDto {
  const UserDto({
    required this.userId,
    required this.username,
    required this.email,
    required this.hasPassword,
    required this.birthDateRegistered,
    required this.agreementsAccepted,
    required this.dailyAttendanceClaimed,
  });

  final int userId;
  final String username;
  final String email;
  final bool hasPassword;
  final bool birthDateRegistered;
  final bool agreementsAccepted;
  final bool dailyAttendanceClaimed;

  factory UserDto.fromJson(Map<String, dynamic> json) => UserDto(
        userId: (json['userId'] as num).toInt(),
        username: json['username'] as String,
        email: json['email'] as String,
        hasPassword: json['hasPassword'] as bool? ?? false,
        birthDateRegistered: json['birthDateRegistered'] as bool? ?? false,
        agreementsAccepted: json['agreementsAccepted'] as bool? ?? false,
        dailyAttendanceClaimed:
            json['dailyAttendanceClaimed'] as bool? ?? true,
      );

  User toEntity() => User(
        userId: userId,
        username: username,
        email: email,
        hasPassword: hasPassword,
        birthDateRegistered: birthDateRegistered,
        agreementsAccepted: agreementsAccepted,
        dailyAttendanceClaimed: dailyAttendanceClaimed,
      );
}
