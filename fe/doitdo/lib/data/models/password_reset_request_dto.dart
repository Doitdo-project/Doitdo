/// `POST /api/auth/password/reset-request` 요청 바디.
///
/// 비밀번호 재설정 1단계 — 가입된 이메일로 인증번호(OTP) 발송 요청.
/// 응답 `data` 는 비어 있어 [EmptyDataDto] 로 받는다.
class PasswordResetRequestDto {
  const PasswordResetRequestDto({required this.email});

  final String email;

  Map<String, dynamic> toJson() => {'email': email};
}
