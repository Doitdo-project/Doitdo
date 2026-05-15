import 'package:doitdo/domain/entities/character.dart';

/// `/api/characters/me` 응답(envelope 내부 `data`) 과 1:1 매핑되는 DTO.
///
/// ```json
/// {
///   "characterId": 0,
///   "name": "string",
///   "stage": "BABY",
///   "thumbnailUrl": "string",
///   "growthPercent": 25,    // 파생 = currentExp * 100 / requiredExp
///   "currentExp": 25,
///   "requiredExp": 100,
///   "canEvolve": false,     // BABY/TEEN 에서 currentExp >= requiredExp
///   "canFarewell": false,   // ADULT 에서 currentExp >= requiredExp
///   "equippedUserItemId": 0,
///   "userCharacterId": 0,
///   "poop": false           // 위생 상태 — true 면 방 안에 똥이 노출됨
/// }
/// ```
class CharacterDto {
  const CharacterDto({
    required this.characterId,
    required this.name,
    required this.stage,
    required this.thumbnailUrl,
    required this.growthPercent,
    required this.currentExp,
    required this.requiredExp,
    required this.canEvolve,
    required this.canFarewell,
    required this.userCharacterId,
    required this.poop,
    this.equippedUserItemId,
  });

  final int characterId;
  final String name;
  final String stage;
  final String thumbnailUrl;
  final int growthPercent;
  final int currentExp;
  final int requiredExp;
  final bool canEvolve;
  final bool canFarewell;
  final int userCharacterId;

  /// 방 안에 똥이 있는지. true 면 캐릭터 카드에 `poop.png` 가 표시된다.
  /// BE 가 점진 배포 중이라 누락 시 false 폴백 — 잘못된 똥 노출보다 누락이 안전.
  final bool poop;

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
      currentExp: (json['currentExp'] as num?)?.toInt() ?? 0,
      requiredExp: (json['requiredExp'] as num?)?.toInt() ?? 0,
      canEvolve: (json['canEvolve'] as bool?) ?? false,
      canFarewell: (json['canFarewell'] as bool?) ?? false,
      userCharacterId: (json['userCharacterId'] as num?)?.toInt() ?? 0,
      poop: (json['poop'] as bool?) ?? false,
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
        currentExp: currentExp,
        requiredExp: requiredExp,
        canEvolve: canEvolve,
        canFarewell: canFarewell,
        equippedUserItemId: equippedUserItemId,
        poop: poop,
      );
}