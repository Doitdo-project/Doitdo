import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/domain/entities/shop_entry.dart';
import 'package:doitdo/domain/entities/shop_furniture.dart';
import 'package:doitdo/domain/entities/user_furniture.dart';
import 'package:doitdo/domain/repositories/shop_repository.dart';
import 'package:doitdo/presentation/pages/shop/shop_state.dart';
import 'package:doitdo/presentation/pages/tamagochi/my_room_provider.dart';
import 'package:doitdo/presentation/providers/app_data_providers.dart';

/// 상점 화면 ViewModel.
///
/// 진입 시 `GET /api/shop/entry` + `GET /api/users/me/furnitures` 를 병렬로
/// 호출해 상점 카탈로그·내 방 배치·보유 가구 매핑을 한 번에 만든다. 뒤의 두
/// 호출이 같이 필요한 이유는 *보유했지만 미배치* 인 가구를 "배치" 하려면
/// `userFurnitureId` 가 필요한데 shop entry 응답에는 그 ID 가 없기 때문.
///
/// 잔액(coin) 은 BE 에 GET 엔드포인트가 아직 없어 진입 시 0 으로 시작하고,
/// `POST /purchase` 응답의 `balance` 로만 갱신된다. wallet GET 이 추가되면
/// [build] 의 `Future.wait` 에 끼워 넣어 초기값을 채워준다.
class ShopViewModel extends AutoDisposeAsyncNotifier<ShopState> {
  late ShopRepository _repo;

  @override
  Future<ShopState> build() async {
    _repo = ref.watch(shopRepositoryProvider);
    final results = await Future.wait([
      _repo.getShopEntry(),
      _repo.listMyFurnitures(),
    ]);
    final entry = results[0] as ShopEntry;
    final myFurnitures = results[1] as List<UserFurnitureItem>;
    return _composeState(entry: entry, myFurnitures: myFurnitures, coins: 0);
  }

  // ─── 동기 액션 (서버 호출 없음) ────────────────────────────────

  void selectCategory(ShopCategory category) {
    final s = state.valueOrNull;
    if (s == null || s.selectedCategory == category) return;
    // 미리보기는 카테고리 전환 후에도 유지 — 다른 카테고리를 둘러보다 다시 돌아오는
    // 흐름에서 매번 토글이 풀리면 짜증날 수 있다.
    state = AsyncData(s.copyWith(selectedCategory: category));
  }

  /// 카드의 "미리보기" 토글. 같은 id 면 끄고, 다른 id 면 교체.
  /// 한 번에 하나만 미리보기 — 방 영역의 표시 결과가 명확하도록.
  void togglePreview(String itemId) {
    final s = state.valueOrNull;
    if (s == null) return;
    if (s.previewingItemId == itemId) {
      state = AsyncData(s.copyWith(clearPreviewing: true));
    } else {
      state = AsyncData(s.copyWith(previewingItemId: itemId));
    }
  }

  // ─── 비동기 액션 (서버 호출) ────────────────────────────────

  /// 미보유 아이템을 구매하고 즉시 방에 배치한다(주문서 확인 모달의 단일 액션).
  ///
  /// 잔액 부족 / 이미 보유 / 판매 중지 등은 BE 가 4xx 로 막고 [false] 로 떨어진다.
  /// 성공 시 새 잔액으로 [ShopState.coins] 를 갱신하고 카탈로그 / 보유 목록을
  /// 재조회. 다마고치 홈 방 배경도 [myRoomProvider] 무효화로 즉시 따라온다.
  Future<bool> purchaseAndPlace(String itemId) async {
    final s = state.valueOrNull;
    if (s == null) return false;
    final item = _findItem(s, itemId);
    if (item == null || item.status != ItemStatus.notOwned) return false;

    try {
      final purchase = await _repo.purchaseFurniture(item.furnitureId);
      await _repo.placeFurniture(purchase.userFurnitureId);
      await _refresh(preserveUi: s, coinsOverride: purchase.balance);
      ref.invalidate(myRoomProvider);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 보유 중 아이템을 방에 배치. 같은 카테고리의 기존 배치는 BE 가 자동 교체한다.
  Future<bool> place(String itemId) async {
    final s = state.valueOrNull;
    if (s == null) return false;
    final item = _findItem(s, itemId);
    if (item == null ||
        item.status != ItemStatus.owned ||
        item.userFurnitureId == null) {
      return false;
    }

    try {
      await _repo.placeFurniture(item.userFurnitureId!);
      await _refresh(preserveUi: s);
      ref.invalidate(myRoomProvider);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 배치된 아이템을 방에서 제거 (보유 가구 자체는 유지).
  Future<bool> unplace(String itemId) async {
    final s = state.valueOrNull;
    if (s == null) return false;
    final item = _findItem(s, itemId);
    if (item == null ||
        item.status != ItemStatus.placed ||
        item.placementId == null) {
      return false;
    }

    try {
      await _repo.removePlacement(item.placementId!);
      await _refresh(preserveUi: s);
      ref.invalidate(myRoomProvider);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── 내부 헬퍼 ────────────────────────────────────────────────

  /// 액션 후 서버 상태를 재조회해 카탈로그·매핑을 갱신.
  /// 카테고리 / 미리보기 / 잔액 같은 UI 상태는 [preserveUi] 에서 그대로 가져온다.
  Future<void> _refresh({
    required ShopState preserveUi,
    int? coinsOverride,
  }) async {
    final results = await Future.wait([
      _repo.getShopEntry(),
      _repo.listMyFurnitures(),
    ]);
    final entry = results[0] as ShopEntry;
    final myFurnitures = results[1] as List<UserFurnitureItem>;
    state = AsyncData(_composeState(
      entry: entry,
      myFurnitures: myFurnitures,
      coins: coinsOverride ?? preserveUi.coins,
      preserveSelected: preserveUi.selectedCategory,
      preservePreviewing: preserveUi.previewingItemId,
    ));
  }

  static ShopItem? _findItem(ShopState s, String id) {
    for (final it in s.items) {
      if (it.id == id) return it;
    }
    return null;
  }

  /// 서버 응답들을 합쳐 화면용 [ShopState] 를 만든다.
  ///
  /// - BACKGROUND 카테고리는 상점 진열 대상이 아니라 필터링.
  /// - placed 인 항목에는 [placementId] 까지 채워서 "해제" API 가 바로 동작.
  /// - selectedCategory 는 [preserveSelected] 우선, 없으면 첫 카테고리, 그도 없으면 [bed].
  static ShopState _composeState({
    required ShopEntry entry,
    required List<UserFurnitureItem> myFurnitures,
    required int coins,
    ShopCategory? preserveSelected,
    String? preservePreviewing,
  }) {
    final ufIdByFurnitureId = <int, int>{
      for (final uf in myFurnitures) uf.furnitureId: uf.userFurnitureId,
    };
    final placementIdByUfId = <int, int>{
      for (final p in entry.room)
        if (p.placementId != null && p.userFurnitureId != null)
          p.userFurnitureId!: p.placementId!,
    };

    final items = <ShopItem>[];
    for (final f in entry.furnitures) {
      final ufId = ufIdByFurnitureId[f.furnitureId];
      final placementId = ufId != null ? placementIdByUfId[ufId] : null;
      items.add(ShopItem(
        id: 'shop_${f.furnitureId}',
        furnitureId: f.furnitureId,
        userFurnitureId: ufId,
        placementId: placementId,
        name: f.name,
        category: ShopCategory.fromServer(f.category),
        price: f.price,
        status: _mapStatus(f.status),
        imageUrl: f.thumbnailUrl.isNotEmpty ? f.thumbnailUrl : f.imageUrl,
      ));
    }

    ShopCategory selected;
    if (preserveSelected != null) {
      selected = preserveSelected;
    } else if (items.isNotEmpty) {
      selected = items.first.category;
    } else {
      selected = ShopCategory.bed;
    }

    return ShopState(
      coins: coins,
      items: items,
      selectedCategory: selected,
      previewingItemId: preservePreviewing,
    );
  }

  static ItemStatus _mapStatus(FurnitureShopStatus s) {
    switch (s) {
      case FurnitureShopStatus.placed:
        return ItemStatus.placed;
      case FurnitureShopStatus.placeable:
        return ItemStatus.owned;
      case FurnitureShopStatus.purchasable:
      case FurnitureShopStatus.unknown:
        return ItemStatus.notOwned;
    }
  }
}

final shopViewModelProvider =
    AsyncNotifierProvider.autoDispose<ShopViewModel, ShopState>(
  ShopViewModel.new,
);
