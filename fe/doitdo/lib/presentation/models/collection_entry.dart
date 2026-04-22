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
    required this.stage,
    required this.thumbnailUrl,
    required this.isUnlocked,
    this.unlockedAt,
    this.birthStory = '',
    this.meetCount = 1,
    this.stageThumbnails = const [],
  });

  final int characterId;

  /// 종 이름. 예: "학자 둥이", "오둥이", "유아둥이".
  final String species;

  /// 성장 단계.
  final CharacterStage stage;

  /// 썸네일 이미지 경로. mock 에서는 로컬 asset 경로, 실서비스에선 네트워크 URL.
  final String thumbnailUrl;

  /// 해금 여부. false 면 "???" 로 표시되고 탭해도 상세를 열지 않는다.
  final bool isUnlocked;

  /// 해금 일시. 미해금이거나 정보 없음이면 null.
  final DateTime? unlockedAt;

  /// 캐릭터의 탄생 배경 설명. 상세 바텀시트에서 "탄생 배경" 섹션에 노출.
  /// 미해금이거나 서버에 스토리가 없으면 빈 문자열.
  final String birthStory;

  /// 이 캐릭터를 지금까지 몇 번 만났는지. 도감 그리드 우상단 `xN` 뱃지에 사용.
  /// 1 이면 뱃지 미표시(기본), 2 이상일 때만 표시한다.
  final int meetCount;

  /// 단계별(baby/teen/adult) 썸네일 경로. 길이 0 또는 3.
  /// 3개가 들어오면 상세 바텀시트 진화 트리에서 이미 거쳐온 단계에도
  /// 해당 단계의 이미지를 그대로 보여준다. 비어 있으면 현재 단계에만
  /// `thumbnailUrl` 을 표시하는 기존 동작으로 폴백한다.
  final List<String> stageThumbnails;

  // ── 상세 화면용 파생 정보 ───────────────────────────────────────────
  // 아래 3개는 UI 시안을 맞추기 위한 임시 파생값이다.
  // 실제 API 가 붙으면 BE 의 `UserCharacter.growthPercent` 등으로 대체한다.

  /// 상세 바텀시트의 성장 단계 라벨. 예: "성장기".
  String get stageLabel => switch (stage) {
        CharacterStage.baby => '탄생기',
        CharacterStage.teen => '성장기',
        CharacterStage.adult => '완성기',
      };

  /// 현재 성장 퍼센티지(0-100). 다음 단계까지의 진행률.
  /// adult 는 최종 단계라 100.
  int get growthPercent => switch (stage) {
        CharacterStage.baby => 30,
        CharacterStage.teen => 62,
        CharacterStage.adult => 100,
      };

  /// 진화 트리. MVP 기준 BE `Character.Stage` 가 BABY/TEEN/ADULT 3단계라
  /// UI 도 3칸으로 맞춘다. 아직 도달하지 않은 단계는 "???" 로 마스킹.
  List<EvolutionStep> get evolutionTree {
    const names = ['알', '성장', '완전체'];
    const levels = [0, 3, 5];
    final currentIndex = switch (stage) {
      CharacterStage.baby => 0,
      CharacterStage.teen => 1,
      CharacterStage.adult => 2,
    };
    final hasPerStageThumbs = stageThumbnails.length == 3;
    return [
      for (var i = 0; i < 3; i++)
        EvolutionStep(
          name: i <= currentIndex ? names[i] : '???',
          level: levels[i],
          thumbnailUrl: _thumbForStage(i, currentIndex, hasPerStageThumbs),
          isUnlocked: i <= currentIndex,
          isCurrent: i == currentIndex,
        ),
    ];
  }

  String _thumbForStage(int i, int currentIndex, bool hasPerStageThumbs) {
    if (i > currentIndex) return '';
    if (hasPerStageThumbs) return stageThumbnails[i];
    // 단계별 썸네일이 없으면 현재 단계에만 대표 썸네일을 쓴다.
    return i == currentIndex ? thumbnailUrl : '';
  }
}

/// 캐릭터 성장 단계. BE `Character.Stage` 와 1:1.
enum CharacterStage { baby, teen, adult }

/// 진화 트리의 한 단계. 상세 바텀시트에서 가로 카드로 나열된다.
@immutable
class EvolutionStep {
  const EvolutionStep({
    required this.name,
    required this.level,
    required this.thumbnailUrl,
    required this.isUnlocked,
    required this.isCurrent,
  });

  final String name;
  final int level;
  final String thumbnailUrl;
  final bool isUnlocked;
  final bool isCurrent;
}
