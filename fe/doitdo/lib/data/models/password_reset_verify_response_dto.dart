/// `POST /api/auth/password/reset/verify-code` 응답 페이로드.
///
/// 인증번호 검증 성공 시 1회용 [resetToken] 을 내려준다.
/// 이 토큰은 3단계 (`POST /api/auth/password/reset`) 의 body 로 그대로 전달.
class PasswordResetVerifyResponseDto {
  const PasswordResetVerifyResponseDto({required this.resetToken});

  final String resetToken;

  factory PasswordResetVerifyResponseDto.fromJson(Map<String, dynamic> json) =>
      PasswordResetVerifyResponseDto(
        resetToken: json['resetToken'] as String,
      );
}
