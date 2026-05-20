/// `POST /api/auth/password/reset` 요청 바디.
///
/// 비밀번호 재설정 3단계(최종) — 2단계에서 받은 [resetToken] 과 새 비밀번호를
/// 함께 보내 실제 비밀번호를 갱신한다. 응답 `data` 는 비어 있어 [EmptyDataDto] 로 받음.
class PasswordResetConfirmRequestDto {
  const PasswordResetConfirmRequestDto({
    required this.resetToken,
    required this.newPassword,
  });

  final String resetToken;
  final String newPassword;

  Map<String, dynamic> toJson() => {
        'resetToken': resetToken,
        'newPassword': newPassword,
      };
}
