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

  User copyWith({
    int? userId,
    String? username,
    String? email,
    bool? hasPassword,
  }) =>
      User(
        userId: userId ?? this.userId,
        username: username ?? this.username,
        email: email ?? this.email,
        hasPassword: hasPassword ?? this.hasPassword,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          username == other.username &&
          email == other.email &&
          hasPassword == other.hasPassword;

  @override
  int get hashCode => Object.hash(userId, username, email, hasPassword);
}
