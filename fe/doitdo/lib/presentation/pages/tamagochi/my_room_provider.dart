import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/data/datasources/room_snapshot_cache.dart';
import 'package:doitdo/domain/entities/room_placement.dart';
import 'package:doitdo/presentation/providers/app_data_providers.dart';

/// 내 방 가구 배치 — `GET /api/users/me/room` 결과를 노출.
///
/// **Stale-while-revalidate** 패턴.
/// 1. build() 진입 시 [RoomSnapshotCache] 에 직전 세션의 스냅샷이 있으면
///    그것을 초기값으로 즉시 emit → 첫 frame 부터 가구가 그려진다.
/// 2. 동시에 백그라운드로 fresh fetch 를 시작. 네트워크 응답이 오면 state 를
///    fresh 로 갱신 + 캐시 덮어쓰기.
/// 3. 캐시가 없으면 (첫 사용자) 그냥 네트워크 fetch 후 응답을 캐시에 적재.
///
/// 가구를 새로 배치·구매·삭제한 직후엔 [MyRoomNotifier.refreshFromNetwork] 를
/// 호출 — `ref.invalidate(myRoomProvider)` 대신. invalidate 는 build 를 다시
/// 돌려 캐시(직전 상태) 를 한 번 emit 하므로 새 변경이 잠깐 안 보이는 깜빡임이
/// 생길 수 있는데, refreshFromNetwork 는 네트워크만 다시 돌려 stale emit 없이
/// fresh 만 떨어뜨린다.
class MyRoomNotifier
    extends AsyncNotifier<List<RoomFurniturePlacement>> {
  @override
  Future<List<RoomFurniturePlacement>> build() async {
    final cache = ref.read(roomSnapshotCacheProvider);
    final cached = cache.read();
    if (cached != null) {
      // 캐시 hit — 즉시 cached 로 시작, 백그라운드로 fresh fetch.
      _refreshFromNetworkSilent();
      return cached;
    }
    // 캐시 없음 — 네트워크 fetch + 캐시 적재.
    return _fetchAndSave();
  }

  /// 가구 변경(구매/이동/삭제) 직후 외부에서 호출. cache emit 없이 fresh 만
  /// 가져와 state 와 캐시 모두 갱신.
  Future<void> refreshFromNetwork() async {
    state = const AsyncLoading<List<RoomFurniturePlacement>>()
        .copyWithPrevious(state);
    try {
      final fresh = await _fetchAndSave();
      state = AsyncData(fresh);
    } catch (e, st) {
      state = AsyncError<List<RoomFurniturePlacement>>(e, st)
          .copyWithPrevious(state);
    }
  }

  /// silent 변형 — state 를 loading 으로 안 바꾸고, 성공 시에만 data 갱신.
  /// 사용자에겐 stale 데이터가 계속 보이다가 fresh 가 도착하면 조용히 교체된다.
  Future<void> _refreshFromNetworkSilent() async {
    try {
      final fresh = await _fetchAndSave();
      state = AsyncData(fresh);
    } catch (_) {
      // 기존 stale state 유지. 다음 시도에서 다시 갱신.
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

final myRoomProvider = AsyncNotifierProvider<MyRoomNotifier,
    List<RoomFurniturePlacement>>(MyRoomNotifier.new);

/// [RoomSnapshotCache] 인스턴스 provider — SharedPreferences 를 주입받는다.
final roomSnapshotCacheProvider = Provider<RoomSnapshotCache>((ref) {
  return RoomSnapshotCache(ref.watch(sharedPreferencesProvider));
});
