import 'package:flutter/foundation.dart';

import 'package:doitdo/domain/entities/room_placement.dart';

/// 상점에서 선택 가능한 가구 "테마" 한 항목.
///
/// 테마 = 같은 컨셉(가을/벚꽃/사이버 등) 으로 묶인 여러 카테고리의 가구 세트.
/// 카드는 메타 정보 + 보유/가격 요약을 보여주고, 실제 미리보기는
/// `GET /api/shop/themes/{themeCode}/preview-room` 호출로 받아 방 영역에 합성한다.
@immutable
class FurnitureTheme {
  const FurnitureTheme({
    required this.themeCode,
    required this.themeName,
    required this.thumbnailUrl,
    required this.furnitureCount,
    required this.ownedCount,
    required this.totalPrice,
    required this.purchasePrice,
    required this.alreadyOwned,
    required this.furnitures,
  });

  /// 테마 식별자. preview-room/purchase/placements 호출 path 에 그대로 들어간다.
  final String themeCode;

  /// 사용자에게 보여줄 이름. 예: `가을`.
  final String themeName;

  /// 카드 썸네일. 비어 있으면 카테고리 폴백 아이콘으로 그린다.
  final String thumbnailUrl;

  /// 테마에 묶인 활성 가구 개수 — "X종 가구" 보조 텍스트로 표시.
  final int furnitureCount;

  /// 사용자가 이미 보유한 가구 수 — 다이얼로그의 "X종 중 Y종 보유" 표시에 사용.
  final int ownedCount;

  /// 테마 전체 정가 합계 — 비교/할인 표시용. 구매 결제는 [purchasePrice] 기준.
  final int totalPrice;

  /// 미보유 가구만 합산한 사용자별 실제 결제 금액. 카드 가격 표시는 이 값.
  final int purchasePrice;

  /// 풀세트 보유 여부. true 면 구매 API 호출 불가 — UI 는 "방에 배치" 만 노출한다.
  final bool alreadyOwned;

  /// 테마 구성 가구 전체 목록. 다이얼로그에서 보유/미보유 표시용.
  final List<ThemeFurniture> furnitures;
}

/// 테마 구성 가구 한 항목 (다이얼로그 행 표시용).
@immutable
class ThemeFurniture {
  const ThemeFurniture({
    required this.furnitureId,
    required this.name,
    required this.category,
    required this.price,
    required this.imageUrl,
    required this.owned,
  });

  final int furnitureId;
  final String name;
  final String category;
  final int price;
  final String imageUrl;

  /// 사용자가 이미 보유 중이면 true — 결제 합계에서 빠지고 다이얼로그에서 "보유" 뱃지.
  final bool owned;
}

/// `POST /api/shop/themes/{themeCode}/purchase` 결과.
///
/// 미보유 가구만 일괄 결제. 자동 배치는 일어나지 않으며 — 호출자가 이어서
/// 배치 API 를 호출해야 한다.
@immutable
class ThemePurchaseResult {
  const ThemePurchaseResult({
    required this.themeCode,
    required this.themeName,
    required this.purchasedCount,
    required this.skippedOwnedCount,
    required this.totalPaid,
    required this.balance,
  });

  final String themeCode;
  final String themeName;

  /// 새로 구매된 가구 수.
  final int purchasedCount;

  /// 이미 보유 중이라 결제에서 제외된 가구 수.
  final int skippedOwnedCount;

  /// 실제 차감된 코인 합계.
  final int totalPaid;

  /// 차감 후 잔액. UI 의 코인 뱃지를 즉시 갱신할 때 사용.
  final int balance;
}

/// `POST /api/users/me/room/themes/{themeCode}/placements` 결과.
///
/// 테마 가구를 한 번에 방에 배치한다. 같은 카테고리에 이미 배치된 가구가 있으면
/// 자동 교체. 응답의 [placedCount] 와 카드의 [FurnitureTheme.furnitureCount] 가
/// 다를 수 있다 (테마가 카테고리 모두를 커버하지 않을 때).
@immutable
class ThemePlacementResult {
  const ThemePlacementResult({
    required this.themeCode,
    required this.themeName,
    required this.placedCount,
    required this.items,
  });

  final String themeCode;
  final String themeName;
  final int placedCount;
  final List<RoomFurniturePlacement> items;
}
