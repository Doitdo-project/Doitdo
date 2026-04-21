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
  static const String _placeholderThumb = 'assets/images/tama_hanrabong.png';

  // 예시용 탄생 배경. 실서비스에선 종별로 다른 스토리가 들어올 자리.
  static const String _sampleStory =
      '오리뚜는 뒤뚱뒤뚱 걷다가 뒤로 엎어졌다가 일어나고 싶다는 강한 열망이 뚜로 다시금 태어나게 되었습니다.';

  /// 디자인 시안 기준 더미 초기값. 6종 중 3종 해금.
  static CollectionState get mock {
    final now = DateTime.now();
    return CollectionState(
      entries: [
        CollectionEntry(
          characterId: 1,
          species: '학자 둥이',
          stage: CharacterStage.adult,
          thumbnailUrl: 'assets/images/tama_fish.png',
          isUnlocked: true,
          unlockedAt: now.subtract(const Duration(days: 30)),
          birthStory: _sampleStory,
          meetCount: 3,
        ),
        CollectionEntry(
          characterId: 2,
          species: '오둥이',
          stage: CharacterStage.teen,
          thumbnailUrl: 'assets/images/tama_hanrabong.png',
          isUnlocked: true,
          unlockedAt: now.subtract(const Duration(days: 10)),
          birthStory: _sampleStory,
          meetCount: 1,
        ),
        CollectionEntry(
          characterId: 3,
          species: '유아둥이',
          stage: CharacterStage.baby,
          thumbnailUrl: 'assets/images/tama_duck.png',
          isUnlocked: true,
          unlockedAt: now.subtract(const Duration(days: 2)),
          birthStory: _sampleStory,
          meetCount: 2,
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
