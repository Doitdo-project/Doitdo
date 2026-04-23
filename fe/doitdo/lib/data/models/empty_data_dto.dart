/// 본문이 없는 응답용 placeholder DTO.
///
/// 로그아웃(DELETE /api/auth/logout) 처럼 `data: {}` 빈 객체를 돌려주는
/// 엔드포인트를 위해 존재. Retrofit 이 [ApiResponse<Object?>] 같은 제네릭은
/// 코드젠 단계에서 `Object.fromJson` 을 호출하려 시도해 실패하므로,
/// 실제 클래스로 타입을 고정해준다.
///
/// 필드는 하나도 없고, [fromJson] 은 입력을 무시하고 빈 인스턴스를 반환.
class EmptyDataDto {
  const EmptyDataDto();

  factory EmptyDataDto.fromJson(Map<String, dynamic> _) => const EmptyDataDto();
}
