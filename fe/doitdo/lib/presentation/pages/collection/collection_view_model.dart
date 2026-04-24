import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/domain/repositories/character_repository.dart';
import 'package:doitdo/presentation/pages/collection/collection_state.dart';
import 'package:doitdo/presentation/providers/app_data_providers.dart';

/// 도감 화면 ViewModel. `GET /api/characters/encyclopedia` 로 로드한 entries 를
/// `CollectionState` 로 감싸 보관한다.
///
/// 상세(birthStory / meetCount / unlockedAt / stageThumbnails) 는 현재 목록
/// API 에 포함되지 않아 기본값으로 채워지고, 별도 상세 엔드포인트가 확정되면
/// `loadDetail(characterId)` 식으로 확장한다.
class CollectionViewModel extends StateNotifier<AsyncValue<CollectionState>> {
  CollectionViewModel(this._repository) : super(const AsyncValue.loading()) {
    load();
  }

  final CharacterRepository _repository;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final entries = await _repository.getEncyclopedia();
      state = AsyncValue.data(CollectionState(entries: entries));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final collectionViewModelProvider = StateNotifierProvider.autoDispose<
    CollectionViewModel, AsyncValue<CollectionState>>(
  (ref) => CollectionViewModel(ref.watch(characterRepositoryProvider)),
);