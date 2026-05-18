import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/data/datasources/room_snapshot_cache.dart';
import 'package:doitdo/domain/entities/room_placement.dart';
import 'package:doitdo/presentation/providers/app_data_providers.dart';

class MyRoomNotifier extends AsyncNotifier<List<RoomFurniturePlacement>> {
  @override
  Future<List<RoomFurniturePlacement>> build() async {
    final cache = ref.read(roomSnapshotCacheProvider);
    final cached = cache.read();
    if (cached != null) {
      _refreshFromNetworkSilent();
      return cached;
    }
    return _fetchAndSave();
  }

  Future<void> refreshFromNetwork() async {
    state = const AsyncLoading<List<RoomFurniturePlacement>>().copyWithPrevious(
      state,
    );
    try {
      final fresh = await _fetchAndSave();
      state = AsyncData(fresh);
    } catch (e, st) {
      state = AsyncError<List<RoomFurniturePlacement>>(
        e,
        st,
      ).copyWithPrevious(state);
    }
  }

  Future<void> replaceWith(List<RoomFurniturePlacement> placements) async {
    final cache = ref.read(roomSnapshotCacheProvider);
    await cache.save(placements);
    state = AsyncData(placements);
  }

  Future<void> _refreshFromNetworkSilent() async {
    try {
      final fresh = await _fetchAndSave();
      state = AsyncData(fresh);
    } catch (_) {
      // Keep the stale room until the next successful refresh.
    }
  }

  Future<List<RoomFurniturePlacement>> _fetchAndSave() async {
    final repo = ref.read(shopRepositoryProvider);
    final cache = ref.read(roomSnapshotCacheProvider);
    final fresh = await repo.getMyRoom();
    await cache.save(fresh);
    return fresh;
  }
}

final myRoomProvider =
    AsyncNotifierProvider<MyRoomNotifier, List<RoomFurniturePlacement>>(
      MyRoomNotifier.new,
    );

final roomSnapshotCacheProvider = Provider<RoomSnapshotCache>((ref) {
  return RoomSnapshotCache(ref.watch(sharedPreferencesProvider));
});
