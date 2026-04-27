import 'package:flutter/foundation.dart';

import 'package:doitdo/presentation/models/collection_entry.dart';

/// 도감 화면 상태 (단일 스냅샷). ViewModel 은 이 상태를 `AsyncValue` 로 감싼다.
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
}