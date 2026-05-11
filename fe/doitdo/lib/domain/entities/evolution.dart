/// 진화 응답을 presentation 레이어가 다룰 수 있게 정제한 형태.
///
/// `POST /api/characters/{userCharacterId}/evolution` 직후 진화 연출(overlay)에
/// 필요한 최소 정보만 들고 있다 — 갱신된 캐릭터 본체(이름/단계/장착아이템 등)는
/// `CharacterViewModel.load()` 가 별도로 당겨 [Character] 로 동기화한다.
class Evolution {
  const Evolution({
    required this.tamagotchiId,
    required this.beforeStage,
    required this.afterStage,
    required this.animationUrl,
    required this.characterImageUrl,
  });

  final int tamagotchiId;

  /// 진화 전 단계 (예: BABY/INFANT). 연출에서 silhouette 표시 후 reveal 비교용.
  final String beforeStage;

  /// 진화 후 단계 (예: TEEN/JUVENILE).
  final String afterStage;

  /// 진화 연출 gif (반짝임 등). overlay 중앙에서 한 번 재생된다.
  final String animationUrl;

  /// 진화 후 캐릭터 이미지. overlay reveal 단계에서 silhouette 자리에 페이드인.
  final String characterImageUrl;
}
