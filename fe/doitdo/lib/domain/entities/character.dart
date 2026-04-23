/// 다마고치 캐릭터의 성장 단계.
///
/// 백엔드는 `stage` 를 문자열로 내려준다. 현재 명세상 확정된 값은 `egg` 뿐이고,
/// 나머지 단계 이름은 추후 확정되므로 [CharacterStage.fromRaw] 가 모르는 값은
/// [CharacterStage.other] 로 흡수한다 (원본은 [Character.rawStage] 에 보존).
enum CharacterStage {
  egg,
  other;

  static CharacterStage fromRaw(String raw) {
    switch (raw.toLowerCase()) {
      case 'egg':
        return CharacterStage.egg;
      default:
        return CharacterStage.other;
    }
  }
}

/// 현재 사용자의 캐릭터.
///
/// `/api/characters/me` 응답을 presentation 레이어가 다룰 수 있게 정제한 형태.
class Character {
  const Character({
    required this.characterId,
    required this.userCharacterId,
    required this.name,
    required this.stage,
    required this.rawStage,
    required this.thumbnailUrl,
    required this.growthPercent,
    this.equippedUserItemId,
  });

  /// 캐릭터 종 ID (도감 기준).
  final int characterId;

  /// 사용자가 소유한 이 캐릭터의 고유 ID.
  final int userCharacterId;

  final String name;

  /// 파싱된 성장 단계. 알 상태 여부는 [isEgg] 로 확인.
  final CharacterStage stage;

  /// 서버가 내려준 원본 stage 문자열. 디버그/로그/미확정 단계 처리에 사용.
  final String rawStage;

  final String thumbnailUrl;

  /// 0 ~ 100. 다음 단계까지 얼마나 자랐는지.
  final int growthPercent;

  /// 장착 중인 아이템 ID. 없으면 null.
  final int? equippedUserItemId;

  bool get isEgg => stage == CharacterStage.egg;
}