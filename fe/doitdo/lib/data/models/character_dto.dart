import 'package:doitdo/domain/entities/character.dart';

/// `/api/characters/me` 응답(envelope 내부 `data`) 과 1:1 매핑되는 DTO.
///
/// ```json
/// {
///   "characterId": 0,
///   "name": "string",
///   "stage": "egg",
///   "thumbnailUrl": "string",
///   "growthPercent": 0,
///   "equippedUserItemId": 0,
///   "userCharacterId": 0
/// }
/// ```
class CharacterDto {
  const CharacterDto({
    required this.characterId,
    required this.name,
    required this.stage,
    required this.thumbnailUrl,
    required this.growthPercent,
    required this.userCharacterId,
    this.equippedUserItemId,
  });

  final int characterId;
  final String name;
  final String stage;
  final String thumbnailUrl;
  final int growthPercent;
  final int userCharacterId;

  /// 아직 아이템을 장착하지 않은 상태(0 또는 null)면 null 로 정규화.
  final int? equippedUserItemId;

  factory CharacterDto.fromJson(Map<String, dynamic> json) {
    final rawEquipped = json['equippedUserItemId'];
    return CharacterDto(
      characterId: (json['characterId'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? '',
      stage: (json['stage'] as String?) ?? '',
      thumbnailUrl: (json['thumbnailUrl'] as String?) ?? '',
      growthPercent: (json['growthPercent'] as num?)?.toInt() ?? 0,
      userCharacterId: (json['userCharacterId'] as num?)?.toInt() ?? 0,
      equippedUserItemId: rawEquipped is num && rawEquipped.toInt() != 0
          ? rawEquipped.toInt()
          : null,
    );
  }

  Character toEntity() => Character(
        characterId: characterId,
        userCharacterId: userCharacterId,
        name: name,
        stage: CharacterStage.fromRaw(stage),
        rawStage: stage,
        thumbnailUrl: thumbnailUrl,
        growthPercent: growthPercent,
        equippedUserItemId: equippedUserItemId,
      );
}