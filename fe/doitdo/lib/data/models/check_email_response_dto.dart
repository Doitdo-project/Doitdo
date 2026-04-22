/// GET /api/users/check-email 응답 페이로드.
///
/// envelope(`{status, message, data}`) 의 `data` 필드 내용과 1:1 매핑.
/// ```json
/// { "available": true }
/// ```
/// BE 응답 필드명이 바뀌면 [fromJson] 만 수정.
class CheckEmailResponseDto {
  const CheckEmailResponseDto({required this.available});

  /// true: 사용 가능(미등록), false: 이미 가입된 이메일.
  final bool available;

  factory CheckEmailResponseDto.fromJson(Map<String, dynamic> json) =>
      CheckEmailResponseDto(available: json['available'] as bool);
}