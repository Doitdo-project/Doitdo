import 'package:flutter/foundation.dart';

import 'package:doitdo/presentation/models/collection_entry.dart';

/// 도감 화면 상태.
///
/// API 붙기 전까지 [mock] 을 ViewModel 이 그대로 반환한다.
@immutable
class CollectionState {
  const CollectionState({required this.entries});

  final List<CollectionEntry> entries;

  int get totalCount => entries.length;
  int get unlockedCount => entries.where((e) => e.isUnlocked).length;

  /// 해금률(0.0 ~ 1.0). 진행도 바에 사용.
  double get progress => totalCount == 0 ? 0 : unlockedCount / totalCount;

  CollectionState copyWith({List<CollectionEntry>? entries}) =>
      CollectionState(entries: entries ?? this.entries);

  // 미해금 칸 썸네일은 어차피 실루엣으로 덮이지만, asset 경로는 유효한 것으로 둔다.
  static const String _placeholderThumb = 'assets/images/tama_fox_1.png';

  // 여우둥이 진화 3단계 썸네일 (baby → teen → adult).
  static const String _foxBaby = 'assets/images/tama_fox_1.png';
  static const String _foxTeen = 'assets/images/tama_fox_2.png';
  static const String _foxAdult = 'assets/images/tama_fox_3.png';

  static const String _foxStory =
      '처음엔 주황빛 젤리처럼 뭉쳐있던 작은 생명이었어요. '
      '매일 할 일을 하나씩 해치우는 당신을 지켜보며 귀가 쫑긋 솟아나고, '
      '어느 날 숲을 자유롭게 뛰노는 여우가 되어 있었답니다.';

  /// 디자인 시안 기준 더미 초기값. 6종 중 여우둥이 1종을 최고 레벨(완성기)까지
  /// 키운 상태로 세팅해, 진화 트리 전체가 채워져 보이도록 한다.
  static CollectionState get mock {
    final now = DateTime.now();
    return CollectionState(
      entries: [
        CollectionEntry(
          characterId: 1,
          species: '여우둥이',
          stage: CharacterStage.adult,
          thumbnailUrl: _foxAdult,
          stageThumbnails: const [_foxBaby, _foxTeen, _foxAdult],
          isUnlocked: true,
          unlockedAt: now.subtract(const Duration(days: 14)),
          birthStory: _foxStory,
          meetCount: 1,
        ),
        const CollectionEntry(
          characterId: 2,
          species: '???',
          stage: CharacterStage.baby,
          thumbnailUrl: _placeholderThumb,
          isUnlocked: false,
        ),
        const CollectionEntry(
          characterId: 3,
          species: '???',
          stage: CharacterStage.baby,
          thumbnailUrl: _placeholderThumb,
          isUnlocked: false,
        ),
        const CollectionEntry(
          characterId: 4,
          species: '???',
          stage: CharacterStage.baby,
          thumbnailUrl: _placeholderThumb,
          isUnlocked: false,
        ),
        const CollectionEntry(
          characterId: 5,
          species: '???',
          stage: CharacterStage.baby,
          thumbnailUrl: _placeholderThumb,
          isUnlocked: false,
        ),
        const CollectionEntry(
          characterId: 6,
          species: '???',
          stage: CharacterStage.baby,
          thumbnailUrl: _placeholderThumb,
          isUnlocked: false,
        ),
      ],
    );
  }
}
