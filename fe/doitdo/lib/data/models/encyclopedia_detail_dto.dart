import 'package:doitdo/presentation/models/collection_entry.dart';

/// `GET /api/characters/encyclopedia/{species}` 응답 envelope 내부 `data`.
///
/// ```json
/// {
///   "species": "CAT",
///   "birthBackground": "9시간 낮잠을 자고 ...",
///   "encounterCount": 3,
///   "baby":  { "characterId": 1, "name": "아기 고양이", "thumbnailUrl": "..." },
///   "teen":  { "characterId": 2, "name": "고양이",     "thumbnailUrl": "..." },
///   "adult": { "characterId": 3, "name": "어른 고양이", "thumbnailUrl": "..." }
/// }
/// ```
class EncyclopediaDetailDto {
  const EncyclopediaDetailDto({
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
  final EncyclopediaStageDto baby;
  final EncyclopediaStageDto teen;
  final EncyclopediaStageDto adult;

  factory EncyclopediaDetailDto.fromJson(Map<String, dynamic> json) {
    return EncyclopediaDetailDto(
      species: (json['species'] as String?) ?? '',
      birthBackground: (json['birthBackground'] as String?) ?? '',
      encounterCount: (json['encounterCount'] as num?)?.toInt() ?? 0,
      baby: EncyclopediaStageDto.fromJson(
        (json['baby'] as Map<String, dynamic>?) ?? const {},
      ),
      teen: EncyclopediaStageDto.fromJson(
        (json['teen'] as Map<String, dynamic>?) ?? const {},
      ),
      adult: EncyclopediaStageDto.fromJson(
        (json['adult'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }

  EncyclopediaDetail toEntity() => EncyclopediaDetail(
        species: species,
        birthBackground: birthBackground,
        encounterCount: encounterCount,
        baby: baby.toEntity(),
        teen: teen.toEntity(),
        adult: adult.toEntity(),
      );
}

class EncyclopediaStageDto {
  const EncyclopediaStageDto({
    required this.characterId,
    required this.name,
    required this.thumbnailUrl,
  });

  final int characterId;
  final String name;
  final String thumbnailUrl;

  factory EncyclopediaStageDto.fromJson(Map<String, dynamic> json) {
    return EncyclopediaStageDto(
      characterId: (json['characterId'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? '',
      thumbnailUrl: (json['thumbnailUrl'] as String?) ?? '',
    );
  }

  EncyclopediaStage toEntity() => EncyclopediaStage(
        characterId: characterId,
        name: name,
        thumbnailUrl: thumbnailUrl,
      );
}
