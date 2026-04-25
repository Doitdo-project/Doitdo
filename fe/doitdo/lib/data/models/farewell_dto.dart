/// `POST /api/characters/me/farewell` 응답 envelope 내부 `data`.
///
/// ```json
/// {
///   "farewellId": 1,
///   "nextCharacterAssigned": true,
///   "nextCharacterStage": "EGG",
///   "animationUrl": "..."
/// }
/// ```
///
/// 독립 승인 후 서버가 다음 알을 자동 배정하므로 UI 는 이 응답을 받은 뒤
/// `GET /api/characters/me` 를 재조회해 새 캐릭터 상태로 갱신한다.
class FarewellDto {
  const FarewellDto({
    required this.farewellId,
    required this.nextCharacterAssigned,
    required this.nextCharacterStage,
    required this.animationUrl,
  });

  final int farewellId;
  final bool nextCharacterAssigned;
  final String nextCharacterStage;
  final String animationUrl;

  factory FarewellDto.fromJson(Map<String, dynamic> json) {
    return FarewellDto(
      farewellId: (json['farewellId'] as num?)?.toInt() ?? 0,
      nextCharacterAssigned: (json['nextCharacterAssigned'] as bool?) ?? false,
      nextCharacterStage: (json['nextCharacterStage'] as String?) ?? '',
      animationUrl: (json['animationUrl'] as String?) ?? '',
    );
  }
}
