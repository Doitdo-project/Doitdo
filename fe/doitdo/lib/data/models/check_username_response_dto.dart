/// `GET /api/users/check-username` 응답 페이로드.
///
/// ```json
/// { "available": true }
/// ```
/// - true: 미사용(가입 시 선점 가능)
/// - false: 이미 사용 중
class CheckUsernameResponseDto {
  const CheckUsernameResponseDto({required this.available});

  final bool available;

  factory CheckUsernameResponseDto.fromJson(Map<String, dynamic> json) =>
      CheckUsernameResponseDto(available: json['available'] as bool);
}
