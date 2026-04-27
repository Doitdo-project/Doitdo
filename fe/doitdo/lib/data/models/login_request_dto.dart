/// `POST /api/auth/login` 요청 바디.
///
/// 백엔드 스펙: `{username, password}` — 로그인은 email 이 아닌 username 기반.
class LoginRequestDto {
  const LoginRequestDto({
    required this.username,
    required this.password,
  });

  final String username;
  final String password;

  Map<String, dynamic> toJson() => {
        'username': username,
        'password': password,
      };
}
