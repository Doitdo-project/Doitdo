/// `POST /api/users/me/birth-date` 요청 바디 (온보딩 1단계).
///
/// 스웨거 스펙:
/// - `birthDate`: ISO-8601 date 문자열 ("YYYY-MM-DD"), required.
///
/// 서버 검증:
/// - 만 14세 미만이면 계정 hard delete + 403 → 호출측에서 에러 메시지 노출 후 Welcome 화면으로.
class RegisterBirthDateRequestDto {
  const RegisterBirthDateRequestDto({required this.birthDate});

  /// ISO-8601 date (YYYY-MM-DD).
  final String birthDate;

  Map<String, dynamic> toJson() => {'birthDate': birthDate};
}
