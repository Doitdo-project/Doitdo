/// 다마고치 캐릭터의 성장 단계. 알 → 유년기 → 성장기 → 성숙기 3+1 단계.
///
/// 백엔드가 `stage` 를 문자열로 내려주는데, 현재 확정된 값은 `EGG` 뿐이고
/// 이후 단계 표기가 확정 전이라 [fromRaw] 가 여러 후보 키워드를 매핑한다.
/// 실제 BE 표기가 확정되면 후보 케이스만 좁히면 된다. 모르는 값은 [other] 로
/// 흡수하고 원본은 [Character.rawStage] 에 보존.
enum CharacterStage {
  egg,
  infant, // 유년기
  juvenile, // 성장기
  adult, // 성숙기
  other;

  static CharacterStage fromRaw(String raw) {
    switch (raw.toUpperCase()) {
      case 'EGG':
        return CharacterStage.egg;
      case 'INFANT':
      case 'BABY':
      case 'CHILD':
      case 'YOUNG':
        return CharacterStage.infant;
      case 'JUVENILE':
      case 'TEEN':
      case 'GROWING':
      case 'YOUTH':
        return CharacterStage.juvenile;
      case 'ADULT':
      case 'MATURE':
      case 'FULL':
        return CharacterStage.adult;
      default:
        return CharacterStage.other;
    }
  }

  /// 경험치 바 위에 붙일 단계 배지 문구. egg/other 단계에서는 숨김(null).
  String? get badgeLabel {
    switch (this) {
      case CharacterStage.infant:
        return '유년기';
      case CharacterStage.juvenile:
        return '성장기';
      case CharacterStage.adult:
        return '성숙기';
      case CharacterStage.egg:
      case CharacterStage.other:
        return null;
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
    required this.currentExp,
    required this.requiredExp,
    required this.canEvolve,
    required this.canFarewell,
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

  /// 0 ~ 100. `currentExp * 100 / requiredExp` 의 서버 파생값. 표시용.
  final int growthPercent;

  /// 현재 단계에서 누적된 경험치.
  final int currentExp;

  /// 현재 단계 진화에 필요한 경험치 총량.
  final int requiredExp;

  /// 진화 가능 여부 (BABY/TEEN 에서 `currentExp >= requiredExp`).
  /// 홈에서 이 플래그의 false→true 에지에서만 진화 API 를 호출한다.
  final bool canEvolve;

  /// 독립(이별) 가능 여부 (ADULT 에서 `currentExp >= requiredExp`).
  final bool canFarewell;

  /// 장착 중인 아이템 ID. 없으면 null.
  final int? equippedUserItemId;

  bool get isEgg => stage == CharacterStage.egg;
}