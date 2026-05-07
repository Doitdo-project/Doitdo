import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/presentation/pages/shop/shop_state.dart';

/// 상점 화면 ViewModel.
///
/// 현재는 BE 연동 전 단계라 in-memory 목 데이터로 동작한다. 코인 잔액·보유/배치
/// 상태는 화면 라이프사이클 동안만 유지된다(autoDispose).
///
/// 한 카테고리 안에는 동시에 하나의 [ItemStatus.placed] 아이템만 존재할 수 있다 —
/// 새 아이템을 배치하면 같은 카테고리의 기존 배치 아이템은 자동으로 owned 로 강등된다.
class ShopViewModel extends StateNotifier<ShopState> {
  ShopViewModel() : super(_initial());

  static ShopState _initial() {
    return ShopState(
      coins: 5200,
      items: _mockItems(),
      selectedCategory: ShopCategory.bed,
    );
  }

  void selectCategory(ShopCategory category) {
    if (state.selectedCategory == category) return;
    // 미리보기는 카테고리 전환 후에도 유지 — 사용자가 다른 카테고리를 둘러보다
    // 다시 돌아오는 흐름에서 매번 토글이 풀리면 짜증날 수 있다.
    state = state.copyWith(selectedCategory: category);
  }

  /// 카드의 "미리보기" 버튼 토글. 같은 id 면 끄고, 다른 id 면 교체.
  /// 한 번에 하나만 미리보기 — 방 영역의 표시 결과가 명확하도록.
  void togglePreview(String itemId) {
    if (state.previewingItemId == itemId) {
      state = state.copyWith(clearPreviewing: true);
      return;
    }
    state = state.copyWith(previewingItemId: itemId);
  }

  /// 미보유 아이템을 구매하고 바로 방에 배치한다(주문서 확인 모달의 단일 액션).
  /// 잔액 부족 시 false 를 반환하고 상태는 그대로 둔다.
  bool purchaseAndPlace(String itemId) {
    final idx = state.items.indexWhere((it) => it.id == itemId);
    if (idx < 0) return false;
    final item = state.items[idx];
    if (item.status != ItemStatus.notOwned) return false;
    if (state.coins < item.price) return false;

    final newItems = _demotePlacedInSameCategory(state.items, item.category);
    newItems[idx] = newItems[idx].copyWith(status: ItemStatus.placed);
    // 구매·배치 직후엔 실제 placed 상태가 미리보기를 대체하므로 토글을 끈다.
    state = state.copyWith(
      coins: state.coins - item.price,
      items: newItems,
      clearPreviewing: true,
    );
    return true;
  }

  /// 보유 중 아이템을 방에 배치. 같은 카테고리의 기존 배치는 자동 해제된다.
  void place(String itemId) {
    final idx = state.items.indexWhere((it) => it.id == itemId);
    if (idx < 0) return;
    final item = state.items[idx];
    if (item.status != ItemStatus.owned) return;

    final newItems = _demotePlacedInSameCategory(state.items, item.category);
    newItems[idx] = newItems[idx].copyWith(status: ItemStatus.placed);
    state = state.copyWith(items: newItems, clearPreviewing: true);
  }

  /// 배치된 아이템을 해제(placed → owned).
  void unplace(String itemId) {
    final idx = state.items.indexWhere((it) => it.id == itemId);
    if (idx < 0) return;
    final item = state.items[idx];
    if (item.status != ItemStatus.placed) return;

    final newItems = [...state.items];
    newItems[idx] = item.copyWith(status: ItemStatus.owned);
    state = state.copyWith(items: newItems, clearPreviewing: true);
  }

  /// 같은 카테고리의 placed 아이템을 owned 로 내린 사본을 만든다.
  /// 한 카테고리 = 한 placed 라는 불변식을 유지하기 위한 헬퍼.
  static List<ShopItem> _demotePlacedInSameCategory(
    List<ShopItem> items,
    ShopCategory category,
  ) {
    return [
      for (final it in items)
        if (it.category == category && it.status == ItemStatus.placed)
          it.copyWith(status: ItemStatus.owned)
        else
          it,
    ];
  }

  static List<ShopItem> _mockItems() {
    final mock = <ShopItem>[];

    void addCategory(
      ShopCategory category,
      List<({String name, int price, ItemStatus status, bool isNew})> entries,
    ) {
      for (var i = 0; i < entries.length; i++) {
        final e = entries[i];
        mock.add(ShopItem(
          id: '${category.name}_$i',
          name: e.name,
          category: category,
          price: e.price,
          status: e.status,
          isNew: e.isNew,
        ));
      }
    }

    addCategory(ShopCategory.wallpaper, [
      (name: '기본 벽지',       price: 0,    status: ItemStatus.placed,   isNew: false),
      (name: '라벤더 별 벽지',  price: 2200, status: ItemStatus.notOwned, isNew: true),
      (name: '하늘 구름 벽지',  price: 1800, status: ItemStatus.notOwned, isNew: false),
      (name: '베이지 라인 벽지', price: 1500, status: ItemStatus.owned,    isNew: false),
    ]);
    addCategory(ShopCategory.tile, [
      (name: '체크 타일',     price: 1200, status: ItemStatus.placed,   isNew: false),
      (name: '대리석 타일',   price: 2000, status: ItemStatus.notOwned, isNew: false),
      (name: '우드 타일',     price: 1800, status: ItemStatus.notOwned, isNew: true),
    ]);
    addCategory(ShopCategory.bed, [
      (name: '딸기 침대',   price: 1500, status: ItemStatus.placed,   isNew: false),
      (name: '보유 침대',   price: 1500, status: ItemStatus.owned,    isNew: false),
      (name: '바닐라 침대', price: 1700, status: ItemStatus.notOwned, isNew: true),
      (name: '민트 침대',   price: 1900, status: ItemStatus.notOwned, isNew: false),
      (name: '코코 침대',   price: 2100, status: ItemStatus.notOwned, isNew: false),
    ]);
    addCategory(ShopCategory.desk, [
      (name: '원목 책상',   price: 1800, status: ItemStatus.placed,   isNew: false),
      (name: '화이트 책상', price: 1600, status: ItemStatus.notOwned, isNew: false),
      (name: '학생 책상',   price: 1400, status: ItemStatus.notOwned, isNew: false),
    ]);
    addCategory(ShopCategory.window, [
      (name: '클래식 창문', price: 1200, status: ItemStatus.placed,   isNew: false),
      (name: '아치 창문',   price: 1800, status: ItemStatus.notOwned, isNew: true),
    ]);
    addCategory(ShopCategory.clock, [
      (name: '벽시계',       price: 800,  status: ItemStatus.placed,   isNew: false),
      (name: '디지털 시계',  price: 1100, status: ItemStatus.notOwned, isNew: false),
    ]);
    addCategory(ShopCategory.tv, [
      (name: '브라운관 티비', price: 1500, status: ItemStatus.placed,   isNew: false),
      (name: '평면 티비',     price: 2200, status: ItemStatus.notOwned, isNew: false),
    ]);
    addCategory(ShopCategory.plant, [
      (name: '선인장',     price: 600,  status: ItemStatus.placed,   isNew: false),
      (name: '몬스테라',   price: 1200, status: ItemStatus.notOwned, isNew: false),
      (name: '튤립 화분',  price: 900,  status: ItemStatus.notOwned, isNew: true),
    ]);
    addCategory(ShopCategory.rug, [
      (name: '꽃무늬 카펫',  price: 1400, status: ItemStatus.placed,   isNew: false),
      (name: '베이지 카펫',  price: 1100, status: ItemStatus.owned,    isNew: false),
      (name: '러그 카펫',    price: 1700, status: ItemStatus.notOwned, isNew: false),
    ]);
    addCategory(ShopCategory.wardrobe, [
      (name: '오크 옷장',  price: 2000, status: ItemStatus.notOwned, isNew: false),
      (name: '화이트 옷장', price: 2400, status: ItemStatus.notOwned, isNew: true),
    ]);
    addCategory(ShopCategory.etc, [
      (name: '액자',     price: 600,  status: ItemStatus.notOwned, isNew: false),
      (name: '캔들',     price: 400,  status: ItemStatus.notOwned, isNew: false),
    ]);

    return mock;
  }
}

final shopViewModelProvider =
    StateNotifierProvider.autoDispose<ShopViewModel, ShopState>(
  (ref) => ShopViewModel(),
);
