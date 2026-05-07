import 'package:flutter/material.dart';

/// 상점 카테고리. 노출 순서대로 정의 — UI 의 카테고리 탭이 그대로 따라간다.
///
/// 서버는 벽지/타일을 따로 두지 않고 [background] 한 카테고리로 방 일러스트
/// 전체를 다룬다. 사용자도 배경을 다른 일러스트로 바꿔치울 수 있다.
enum ShopCategory {
  background('배경', Icons.image_outlined),
  bed('침대', Icons.bed_outlined),
  desk('책상', Icons.desk_outlined),
  window('창문', Icons.window_outlined),
  clock('시계', Icons.access_time_rounded),
  tv('티비', Icons.tv_outlined),
  plant('화분', Icons.local_florist_outlined),
  rug('카펫', Icons.texture_rounded),
  etc('기타', Icons.more_horiz_rounded);

  const ShopCategory(this.label, this.icon);

  final String label;
  final IconData icon;

  /// 서버 응답의 대문자 카테고리 문자열을 enum 으로 변환.
  ///
  /// 미정의 / 빈 값은 [etc] 로 흡수해 분류만 분리하고 노출은 시킨다 — UI 가
  /// 깨지지 않도록.
  static ShopCategory fromServer(String? raw) {
    switch (raw?.toUpperCase()) {
      case 'BACKGROUND':
        return ShopCategory.background;
      case 'BED':
        return ShopCategory.bed;
      case 'DESK':
        return ShopCategory.desk;
      case 'WINDOW':
        return ShopCategory.window;
      case 'CLOCK':
        return ShopCategory.clock;
      case 'TV':
        return ShopCategory.tv;
      case 'PLANT':
        return ShopCategory.plant;
      case 'RUG':
        return ShopCategory.rug;
      default:
        return ShopCategory.etc;
    }
  }
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
    required this.furnitureId,
    required this.name,
    required this.category,
    required this.price,
    required this.status,
    required this.imageUrl,
    this.userFurnitureId,
    this.placementId,
  });

  /// 화면 비교용 안정 ID. 보통 `'shop_$furnitureId'` 형식.
  final String id;

  /// 가구 마스터 ID (= `Furniture.furnitureId`). 구매 시 path param 으로 들어간다.
  final int furnitureId;

  /// 보유 시 채워지는 사용자별 가구 인스턴스 ID. 배치/해제 API path 에 필요.
  final int? userFurnitureId;

  /// 배치 시 채워지는 placement ID. 해제 API path 에 필요.
  final int? placementId;

  final String name;
  final ShopCategory category;
  final int price;
  final ItemStatus status;

  /// 카드 / 미리보기에 띄울 이미지. 비어있으면 카테고리 아이콘으로 폴백.
  /// shop entry 응답의 thumbnailUrl 우선, 없으면 imageUrl.
  final String imageUrl;

  ShopItem copyWith({ItemStatus? status}) => ShopItem(
        id: id,
        furnitureId: furnitureId,
        userFurnitureId: userFurnitureId,
        placementId: placementId,
        name: name,
        category: category,
        price: price,
        status: status ?? this.status,
        imageUrl: imageUrl,
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
