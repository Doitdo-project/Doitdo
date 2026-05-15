import 'package:flutter/material.dart';

import 'package:doitdo/domain/entities/furniture_theme.dart';

/// 상점 상단 탭. 가구 카탈로그 탭과 테마 카드 탭을 구분한다.
///
/// 두 탭은 미리보기 컨텍스트가 서로 배타적이다 — 가구 멀티 미리보기와 테마
/// 미리보기는 동시에 켜두지 않는다. 탭 전환 시 반대편 미리보기는 ViewModel 에서
/// 해제한다.
enum ShopTab {
  furniture('가구'),
  theme('테마');

  const ShopTab(this.label);
  final String label;
}

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
    required this.themes,
    required this.selectedTab,
    required this.selectedCategory,
    this.previewingItemIds = const {},
    this.previewingThemeCode,
    this.themePreviewItems,
  });

  final int coins;
  final List<ShopItem> items;

  /// 테마 탭에서 노출할 테마 카드 목록. 첫 진입 시 1회 로드.
  final List<FurnitureTheme> themes;

  /// 상단 가구/테마 탭.
  final ShopTab selectedTab;
  final ShopCategory selectedCategory;

  /// 가구 멀티 미리보기 — 카테고리당 1개씩 토글한 itemId 매핑.
  /// 같은 카테고리에서 다른 카드를 탭하면 그 카테고리의 미리보기가 교체된다.
  /// 같은 카드를 한 번 더 탭하면 해당 카테고리만 빠진다.
  /// 다른 카테고리는 서로 영향 없음 → 침대 + 책상 + 창문을 동시에 미리볼 수 있음.
  final Map<ShopCategory, String> previewingItemIds;

  /// 테마 미리보기 활성 코드. null 이면 비활성.
  /// 가구 멀티 미리보기와 상호 배타 — 한 쪽이 켜지면 반대편은 해제된다.
  final String? previewingThemeCode;

  /// `GET /shop/themes/{code}/preview-room` 응답을 [ShopItem] 으로 합성한 것.
  /// [previewingThemeCode] 가 null 이 아닐 때만 채워진다. 방 미리보기 영역 렌더용.
  final List<ShopItem>? themePreviewItems;

  /// 특정 가구 카드가 현재 미리보기 토글 중인지.
  bool isPreviewing(String itemId) =>
      previewingItemIds.values.contains(itemId);

  /// 특정 테마 카드가 현재 미리보기 활성인지.
  bool isThemePreviewing(String themeCode) =>
      previewingThemeCode == themeCode;

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

  /// 방 미리보기 영역에 그릴 아이템들.
  ///
  /// 우선순위:
  /// 1) 테마 미리보기 활성 → 서버 합성 응답을 그대로 그린다.
  /// 2) 가구 멀티 미리보기 + placed → 미리보기 카테고리는 미리보기 항목으로
  ///    교체, 그 외 카테고리는 placed 유지.
  /// 3) 둘 다 비활성 → placed 만.
  List<ShopItem> get displayItems {
    if (themePreviewItems != null) return themePreviewItems!;

    if (previewingItemIds.isEmpty) return placedItems;

    final previewedCategories = previewingItemIds.keys.toSet();
    final preserved = placedItems.where(
      (it) => !previewedCategories.contains(it.category),
    );
    // 미리보기 itemId → ShopItem 매핑 (못 찾으면 누락하고 진행 — 데이터 정합성 깨짐 방지).
    final byId = <String, ShopItem>{for (final it in items) it.id: it};
    final previewing = previewingItemIds.values
        .map((id) => byId[id])
        .whereType<ShopItem>()
        .toList(growable: false);
    return [...preserved, ...previewing];
  }

  /// nullable 필드의 명시적 비우기를 위한 플래그들 — 단순 `null` 전달만으론
  /// "기존 값 유지" 와 구분이 안 되므로 [clearXxx] 로 의도를 분리.
  ShopState copyWith({
    int? coins,
    List<ShopItem>? items,
    List<FurnitureTheme>? themes,
    ShopTab? selectedTab,
    ShopCategory? selectedCategory,
    Map<ShopCategory, String>? previewingItemIds,
    String? previewingThemeCode,
    List<ShopItem>? themePreviewItems,
    bool clearThemePreview = false,
  }) =>
      ShopState(
        coins: coins ?? this.coins,
        items: items ?? this.items,
        themes: themes ?? this.themes,
        selectedTab: selectedTab ?? this.selectedTab,
        selectedCategory: selectedCategory ?? this.selectedCategory,
        previewingItemIds: previewingItemIds ?? this.previewingItemIds,
        previewingThemeCode: clearThemePreview
            ? null
            : (previewingThemeCode ?? this.previewingThemeCode),
        themePreviewItems: clearThemePreview
            ? null
            : (themePreviewItems ?? this.themePreviewItems),
      );
}
