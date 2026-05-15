/// `POST /api/auth/password/reset/verify-code` 요청 바디.
///
/// 비밀번호 재설정 2단계 — 1단계에서 이메일로 받은 인증번호(`code`) 검증.
/// 성공 시 [PasswordResetVerifyResponseDto.resetToken] 으로 짧은 수명의 1회용
/// 재설정 토큰을 발급받고, 3단계 (`/api/auth/password/reset`) 호출에 사용한다.
class PasswordResetVerifyRequestDto {
  const PasswordResetVerifyRequestDto({
    required this.email,
    required this.code,
  });

  final String email;
  final String code;

  Map<String, dynamic> toJson() => {
        'email': email,
        'code': code,
      };
}
