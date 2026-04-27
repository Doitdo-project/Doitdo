import 'package:doitdo/presentation/models/collection_entry.dart';

/// `/api/characters/encyclopedia` 응답 envelope 내부 `data`.
///
/// ```json
/// { "items": [
///   {
///     "characterId": 3,
///     "name": "어른 고양이",
///     "species": "CAT",
///     "stage": "ADULT",
///     "unlocked": true,
///     "thumbnailUrl": "..."
///   }
/// ] }
/// ```
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
    required this.name,
    required this.species,
    required this.stage,
    required this.unlocked,
    required this.thumbnailUrl,
  });

  final int characterId;
  final String name;
  final String species;
  final String stage;
  final bool unlocked;
  final String thumbnailUrl;

  factory EncyclopediaItemDto.fromJson(Map<String, dynamic> json) {
    return EncyclopediaItemDto(
      characterId: (json['characterId'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? '',
      species: (json['species'] as String?) ?? '',
      stage: (json['stage'] as String?) ?? '',
      unlocked: (json['unlocked'] as bool?) ?? false,
      thumbnailUrl: (json['thumbnailUrl'] as String?) ?? '',
    );
  }

  /// BE stage 문자열 → 도감 3단계 UI 모델로 축약.
  /// 도감은 BABY / TEEN / ADULT 3단계만 다루고 EGG 는 리스트에 노출되지 않는다.
  CharacterStage toCollectionStage() {
    switch (stage.toUpperCase()) {
      case 'TEEN':
      case 'JUVENILE':
      case 'GROWING':
      case 'YOUTH':
        return CharacterStage.teen;
      case 'ADULT':
      case 'MATURE':
      case 'FULL':
        return CharacterStage.adult;
      case 'BABY':
      case 'INFANT':
      case 'CHILD':
      case 'YOUNG':
      case 'EGG':
      default:
        return CharacterStage.baby;
    }
  }

  CollectionEntry toEntry() => CollectionEntry(
        characterId: characterId,
        species: species,
        // 미해금 항목의 name 은 UI 에서 "???" 로 가릴 것이라 빈 문자열로.
        name: unlocked ? name : '',
        stage: toCollectionStage(),
        thumbnailUrl: thumbnailUrl,
        isUnlocked: unlocked,
      );
}
