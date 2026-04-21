/// 앱 전체에서 공유되는 유저 도메인 모델.
///
/// 소셜 로그인 종류/플랫폼과 무관하게 프레젠테이션 레이어는 이 모델만 본다.
/// 서버 응답이나 OAuth 원본 토큰은 여기 들어오지 않는다 — 그건 data 레이어 DTO 영역.
class User {
  const User({
    required this.id,
    required this.nickname,
    required this.email,
  });

  final int id;
  final String nickname;
  final String email;

  User copyWith({int? id, String? nickname, String? email}) => User(
        id: id ?? this.id,
        nickname: nickname ?? this.nickname,
        email: email ?? this.email,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          nickname == other.nickname &&
          email == other.email;

  @override
  int get hashCode => Object.hash(id, nickname, email);
}
