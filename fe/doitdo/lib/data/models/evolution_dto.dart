import 'package:doitdo/domain/entities/evolution.dart';

/// `POST /api/characters/{userCharacterId}/evolution` 응답 envelope 내부 `data`.
///
/// ```json
/// {
///   "tamagotchiId": 1,
///   "beforeStage": "INFANT",
///   "afterStage": "JUVENILE",
///   "currentExp": 0,
///   "requiredExp": 100,
///   "animationUrl": "...",
///   "characterImageUrl": "...",
///   "evolvedAt": "2026-04-24T10:00:00"
/// }
/// ```
///
/// 진화 후의 전체 캐릭터 정보는 `GET /api/characters/me` 를 다시 당겨 갱신한다.
/// 이 DTO 는 진화 연출(animationUrl) / 스테이지 전환 확인 용도로만 사용.
class EvolutionDto {
  const EvolutionDto({
    required this.tamagotchiId,
    required this.beforeStage,
    required this.afterStage,
    required this.currentExp,
    required this.requiredExp,
    required this.animationUrl,
    required this.characterImageUrl,
    required this.evolvedAt,
  });

  final int tamagotchiId;
  final String beforeStage;
  final String afterStage;
  final int currentExp;
  final int requiredExp;
  final String animationUrl;
  final String characterImageUrl;
  final String evolvedAt;

  factory EvolutionDto.fromJson(Map<String, dynamic> json) {
    return EvolutionDto(
      tamagotchiId: (json['tamagotchiId'] as num?)?.toInt() ?? 0,
      beforeStage: (json['beforeStage'] as String?) ?? '',
      afterStage: (json['afterStage'] as String?) ?? '',
      currentExp: (json['currentExp'] as num?)?.toInt() ?? 0,
      requiredExp: (json['requiredExp'] as num?)?.toInt() ?? 0,
      animationUrl: (json['animationUrl'] as String?) ?? '',
      characterImageUrl: (json['characterImageUrl'] as String?) ?? '',
      evolvedAt: (json['evolvedAt'] as String?) ?? '',
    );
  }

  Evolution toEntity() => Evolution(
        tamagotchiId: tamagotchiId,
        beforeStage: beforeStage,
        afterStage: afterStage,
        animationUrl: animationUrl,
        characterImageUrl: characterImageUrl,
      );
}