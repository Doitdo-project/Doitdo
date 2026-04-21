import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/presentation/pages/collection/collection_state.dart';

/// 도감 화면 ViewModel.
///
/// 현재는 API 가 없어 `CollectionState.mock` 을 그대로 사용한다.
/// Repository 가 붙으면 `ref` 로 주입받아 `load()` 에서 실제 데이터를
/// 가져오도록 확장한다. 그 시점에 `AsyncNotifier` 로 승격할 수 있다.
class CollectionViewModel extends StateNotifier<CollectionState> {
  CollectionViewModel() : super(CollectionState.mock);
}

final collectionViewModelProvider =
    StateNotifierProvider.autoDispose<CollectionViewModel, CollectionState>(
  (ref) => CollectionViewModel(),
);
