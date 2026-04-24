import 'package:doitdo/presentation/models/collection_entry.dart';

/// `/api/characters/encyclopedia` 응답 envelope 내부 `data` 에 1:1.
///
/// ```json
/// { "items": [ { "characterId": 1, "species": "여우둥이", "stage": "ADULT",
///               "unlocked": true, "thumbnailUrl": "..." }, ... ] }
/// ```
///
/// 상세(탄생 배경 / meetCount / 해금 일시 / 단계별 썸네일) 은 별도 엔드포인트로
/// 확정 전이라 여기서는 리스트 정보만 담는다. 상세가 나오면 별도 DTO 추가.
class EncyclopediaDto {
  const EncyclopediaDto({required this.items});

  final List<EncyclopediaItemDto> items;

  factory EncyclopediaDto.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    return EncyclopediaDto(
      items: raw is List
          ? raw
              .whereType<Map<String, dynamic>>()
              .map(EncyclopediaItemDto.fromJson)
              .toList()
          : const [],
    );
  }
}

class EncyclopediaItemDto {
  const EncyclopediaItemDto({
    required this.characterId,
    required this.species,
    required this.stage,
    required this.unlocked,
    required this.thumbnailUrl,
  });

  final int characterId;
  final String species;
  final String stage;
  final bool unlocked;
  final String thumbnailUrl;

  factory EncyclopediaItemDto.fromJson(Map<String, dynamic> json) {
    return EncyclopediaItemDto(
      characterId: (json['characterId'] as num?)?.toInt() ?? 0,
      species: (json['species'] as String?) ?? '',
      stage: (json['stage'] as String?) ?? '',
      unlocked: (json['unlocked'] as bool?) ?? false,
      thumbnailUrl: (json['thumbnailUrl'] as String?) ?? '',
    );
  }

  /// BE stage 문자열 → 도감 3단계 UI 모델로 축약.
  ///
  /// 도감 UI 는 baby / teen / adult 3칸이지만 BE 는 EGG, INFANT, JUVENILE, ADULT 등
  /// 4+ 단계를 내려줄 수 있다. MVP 기준 "미해금이면 아직 알, 부화했으면 해당 단계"
  /// 로만 구분하면 충분하다.
  CharacterStage toCollectionStage() {
    switch (stage.toUpperCase()) {
      case 'JUVENILE':
      case 'TEEN':
      case 'GROWING':
      case 'YOUTH':
        return CharacterStage.teen;
      case 'ADULT':
      case 'MATURE':
      case 'FULL':
        return CharacterStage.adult;
      case 'EGG':
      case 'INFANT':
      case 'BABY':
      case 'CHILD':
      case 'YOUNG':
      default:
        return CharacterStage.baby;
    }
  }

  CollectionEntry toEntry() => CollectionEntry(
        characterId: characterId,
        species: unlocked ? species : '???',
        stage: toCollectionStage(),
        thumbnailUrl: thumbnailUrl,
        isUnlocked: unlocked,
      );
}