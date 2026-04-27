import 'package:flutter/foundation.dart';

/// 다마고치 도감 엔트리 경량 모델.
///
/// BE 의 `Character` + `CharacterUnlock` 을 합친 형태.
/// 도메인 엔티티가 확정되기 전까지 프레젠테이션에서 사용하는 임시 모델이다.
/// API 연동 시 `data/models/*Dto` → `domain/entities/Character` → 이 모델로
/// 매핑하도록 한다.
@immutable
class CollectionEntry {
  const CollectionEntry({
    required this.characterId,
    required this.species,
    required this.name,
    required this.stage,
    required this.thumbnailUrl,
    required this.isUnlocked,
  });

  final int characterId;

  /// BE 의 종 enum (URL path param 으로 사용). 예: "CAT", "FOX".
  final String species;

  /// 표시용 캐릭터 이름 (BE `name`). 예: "어른 고양이".
  /// 미해금일 땐 빈 문자열이며 UI 에서 "???" 로 가린다.
  final String name;

  /// 성장 단계.
  final CharacterStage stage;

  /// 썸네일 이미지 URL. 미해금이어도 BE 가 내려주면 들어온다.
  final String thumbnailUrl;

  /// 해금 여부. false 면 "???" 로 표시되고 탭해도 상세를 열지 않는다.
  final bool isUnlocked;

  /// 상세 바텀시트의 성장 단계 라벨. 다마고치 홈의 [Character.stage.badgeLabel]
  /// 과 동일한 표기를 쓴다 (유년기 / 성장기 / 성숙기).
  String get stageLabel => stageLabelOf(stage);
}

/// 캐릭터 성장 단계. BE `Character.Stage` 와 1:1 (EGG 는 도감에 잡히지 않음).
enum CharacterStage { baby, teen, adult }

/// 홈과 통일된 단계 라벨 매핑. [Character.stage.badgeLabel] 과 동일.
String stageLabelOf(CharacterStage stage) => switch (stage) {
      CharacterStage.baby => '유년기',
      CharacterStage.teen => '성장기',
      CharacterStage.adult => '성숙기',
    };

/// `/api/characters/encyclopedia/{species}` 상세 응답의 도메인 모델.
@immutable
class EncyclopediaDetail {
  const EncyclopediaDetail({
    required this.species,
    required this.birthBackground,
    required this.encounterCount,
    required this.baby,
    required this.teen,
    required this.adult,
  });

  final String species;
  final String birthBackground;
  final int encounterCount;
  final EncyclopediaStage baby;
  final EncyclopediaStage teen;
  final EncyclopediaStage adult;

  /// baby→teen→adult 순서의 리스트 편의 getter. UI 진화 트리 렌더에 사용.
  List<({CharacterStage stage, EncyclopediaStage data})> get stagesInOrder => [
        (stage: CharacterStage.baby, data: baby),
        (stage: CharacterStage.teen, data: teen),
        (stage: CharacterStage.adult, data: adult),
      ];
}

/// 상세 응답의 단일 진화 단계 정보.
@immutable
class EncyclopediaStage {
  const EncyclopediaStage({
    required this.characterId,
    required this.name,
    required this.thumbnailUrl,
  });

  final int characterId;
  final String name;
  final String thumbnailUrl;
}
