/// `POST /api/users/me/password` 요청 바디.
///
/// 스웨거 스펙:
/// - `currentPassword`: 현재 비밀번호
/// - `newPassword`: 새 비밀번호 (8 ~ 255자)
class ChangePasswordRequestDto {
  const ChangePasswordRequestDto({
    required this.currentPassword,
    required this.newPassword,
  });

  final String currentPassword;
  final String newPassword;

  Map<String, dynamic> toJson() => {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      };
}
