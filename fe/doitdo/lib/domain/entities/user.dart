/// 앱 전체에서 공유되는 유저 도메인 모델.
///
/// 소셜 로그인 종류/플랫폼과 무관하게 프레젠테이션 레이어는 이 모델만 본다.
/// 서버 응답이나 OAuth 원본 토큰은 여기 들어오지 않는다 — 그건 data 레이어 DTO 영역.
///
/// 필드명은 백엔드 스펙(`userId`, `username`) 과 동일하게 유지한다.
class User {
  const User({
    required this.userId,
    required this.username,
    required this.email,
    required this.hasPassword,
    required this.birthDateRegistered,
    required this.agreementsAccepted,
    this.dailyAttendanceClaimed = false,
  });

  /// 서버 PK (`userId`).
  final int userId;

  /// 로그인 계정명 겸 표시용 닉네임 (`username`).
  final String username;

  /// 이메일 주소.
  final String email;

  /// 이 계정이 자체 비밀번호를 가지고 있는지 여부.
  ///
  /// 백엔드의 `password` 필드가 null 이 아니면 true (= 일반 이메일 가입).
  /// 소셜(Kakao/Google/Apple) 전용 가입자는 false → "비밀번호 변경" 진입을 숨겨야 한다.
  final bool hasPassword;

  /// 온보딩 1단계 — 생년월일 등록 완료 여부.
  ///
  /// 첫 로그인(이메일/소셜 가리지 않고) 시점에 false 면 BirthDate 온보딩 화면으로 보낸다.
  /// 서버 스펙: `UserInfoResp.birthDateRegistered`.
  final bool birthDateRegistered;

  /// 온보딩 2단계 — 약관(이용약관/개인정보처리방침/마케팅) 동의 완료 여부.
  ///
  /// 1단계가 끝났는데 false 면 Agreements 화면으로 보낸다.
  /// 서버 스펙: `UserInfoResp.agreementsAccepted`.
  final bool agreementsAccepted;

  /// 오늘 자동 출석 보상이 이미 지급/안내 처리됐는지.
  ///
  /// BE 가 진입 첫 GET 응답에서만 false 로 내려주고, 그 직후 자동으로 true 로
  /// 토글한다. 클라는 false 를 본 시점에 +100 코인 알림(스낵바 + floating "+100")
  /// 만 띄우면 된다 — 실제 보상 지급은 서버가 처리하므로 별도 claim 호출 X.
  /// 서버 스펙: `UserInfoResp.dailyAttendanceClaimed`.
  final bool dailyAttendanceClaimed;

  /// 두 단계 모두 끝난 사용자만 메인 탭으로 진입시킨다.
  bool get isOnboardingComplete => birthDateRegistered && agreementsAccepted;

  User copyWith({
    int? userId,
    String? username,
    String? email,
    bool? hasPassword,
    bool? birthDateRegistered,
    bool? agreementsAccepted,
    bool? dailyAttendanceClaimed,
  }) =>
      User(
        userId: userId ?? this.userId,
        username: username ?? this.username,
        email: email ?? this.email,
        hasPassword: hasPassword ?? this.hasPassword,
        birthDateRegistered: birthDateRegistered ?? this.birthDateRegistered,
        agreementsAccepted: agreementsAccepted ?? this.agreementsAccepted,
        dailyAttendanceClaimed:
            dailyAttendanceClaimed ?? this.dailyAttendanceClaimed,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          username == other.username &&
          email == other.email &&
          hasPassword == other.hasPassword &&
          birthDateRegistered == other.birthDateRegistered &&
          agreementsAccepted == other.agreementsAccepted &&
          dailyAttendanceClaimed == other.dailyAttendanceClaimed;

  @override
  int get hashCode => Object.hash(
        userId,
        username,
        email,
        hasPassword,
        birthDateRegistered,
        agreementsAccepted,
        dailyAttendanceClaimed,
      );
}
