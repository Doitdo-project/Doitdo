import 'package:flutter/material.dart';

/// 상점 카테고리. 노출 순서대로 정의 — UI 의 카테고리 탭이 그대로 따라간다.
enum ShopCategory {
  wallpaper('벽지', Icons.wallpaper_outlined),
  tile('타일', Icons.grid_4x4_rounded),
  bed('침대', Icons.bed_outlined),
  desk('책상', Icons.desk_outlined),
  window('창문', Icons.window_outlined),
  clock('시계', Icons.access_time_rounded),
  tv('티비', Icons.tv_outlined),
  plant('화분', Icons.local_florist_outlined),
  carpet('카펫', Icons.texture_rounded),
  closet('옷장', Icons.checkroom_rounded),
  etc('기타', Icons.more_horiz_rounded);

  const ShopCategory(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// 상품 보유 상태.
/// - [notOwned] : 미보유 → 카드에 가격 + "구매" 버튼.
/// - [owned]    : 보유 → "보유" 뱃지 + "배치" 버튼.
/// - [placed]   : 방에 배치 중 → "배치중" 뱃지 + "해제" 버튼.
enum ItemStatus { notOwned, owned, placed }

@immutable
class ShopItem {
  const ShopItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.status,
    this.isNew = false,
  });

  final String id;
  final String name;
  final ShopCategory category;
  final int price;
  final ItemStatus status;
  final bool isNew;

  ShopItem copyWith({ItemStatus? status}) => ShopItem(
        id: id,
        name: name,
        category: category,
        price: price,
        status: status ?? this.status,
        isNew: isNew,
      );
}

@immutable
class ShopState {
  const ShopState({
    required this.coins,
    required this.items,
    required this.selectedCategory,
    this.previewingItemId,
  });

  final int coins;
  final List<ShopItem> items;
  final ShopCategory selectedCategory;

  /// 카드의 "미리보기" 토글로 방 영역에 임시 적용된 아이템 id. 동시에 하나만.
  /// 실제 [ShopItem.status] 는 변하지 않고 [displayItems] 합성 단계에서만 반영된다.
  final String? previewingItemId;

  /// 현재 선택된 카테고리에서만 노출되는 아이템.
  /// 정렬: 배치중 → 보유 → 미보유, 그 안에서는 등록 순서.
  List<ShopItem> get visibleItems {
    final filtered = items.where((it) => it.category == selectedCategory).toList();
    filtered.sort((a, b) => a.status.index.compareTo(b.status.index));
    // 위 정렬은 enum 인덱스(notOwned=0,owned=1,placed=2) 기준이라 배치중이 마지막에 옴 → 역정렬.
    return filtered.reversed.toList(growable: false);
  }

  /// 실제로 방에 "구매·배치" 된 아이템(전 카테고리 통합).
  List<ShopItem> get placedItems =>
      items.where((it) => it.status == ItemStatus.placed).toList(growable: false);

  /// 미리보기 토글 중인 아이템(없으면 null).
  ShopItem? get previewingItem {
    if (previewingItemId == null) return null;
    for (final it in items) {
      if (it.id == previewingItemId) return it;
    }
    return null;
  }

  /// 방 미리보기 영역에 그릴 아이템들.
  /// = placed 항목 중 previewing 과 같은 카테고리는 빼고, 마지막에 previewing 추가.
  /// 미리보기가 없으면 [placedItems] 와 동일.
  List<ShopItem> get displayItems {
    final preview = previewingItem;
    if (preview == null) return placedItems;
    return [
      ...placedItems.where((it) => it.category != preview.category),
      preview,
    ];
  }

  /// [previewingItemId] 만 명시적으로 비우려면 [clearPreviewing]=true 를 넘긴다
  /// (nullable 필드라 단순 `previewingItemId: null` 만으로는 "기존 값 유지"와 구분이 안 됨).
  ShopState copyWith({
    int? coins,
    List<ShopItem>? items,
    ShopCategory? selectedCategory,
    String? previewingItemId,
    bool clearPreviewing = false,
  }) =>
      ShopState(
        coins: coins ?? this.coins,
        items: items ?? this.items,
        selectedCategory: selectedCategory ?? this.selectedCategory,
        previewingItemId: clearPreviewing
            ? null
            : (previewingItemId ?? this.previewingItemId),
      );
}
