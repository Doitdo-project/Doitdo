/// `POST /api/auth/signup` 요청 바디.
///
/// 스펙: `{email, password, username}` — 세 필드 모두 필수.
class SignUpRequestDto {
  const SignUpRequestDto({
    required this.email,
    required this.password,
    required this.username,
  });

  final String email;
  final String password;
  final String username;

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'username': username,
      };
}
