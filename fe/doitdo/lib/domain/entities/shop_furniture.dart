import 'package:flutter/foundation.dart';

/// 상점 가구 항목의 노출 상태.
///
/// BE [FurnitureShopStatus] enum 과 1:1 매핑된다.
/// - [purchasable]: 미보유 상태 — "구매하기" 버튼 노출.
/// - [placeable]  : 보유했지만 방에 배치 안 됨 — "내 방에 두기" 버튼 노출.
/// - [placed]     : 이미 방에 배치됨 — 비활성/배치됨 표시.
enum FurnitureShopStatus {
  purchasable,
  placeable,
  placed,
  unknown;

  /// BE 가 미래에 새 enum 값을 추가해도 [unknown] 으로 흡수한다 — UI 가 기존
  /// 분기와 충돌해서 깨지는 일을 막기 위해.
  static FurnitureShopStatus fromRaw(String? raw) {
    switch (raw?.toUpperCase()) {
      case 'PURCHASABLE':
        return FurnitureShopStatus.purchasable;
      case 'PLACEABLE':
        return FurnitureShopStatus.placeable;
      case 'PLACED':
        return FurnitureShopStatus.placed;
      default:
        return FurnitureShopStatus.unknown;
    }
  }
}

/// 상점 진열대에 올라가는 가구 한 항목.
///
/// 동일 가구라도 사용자 보유/배치 상태에 따라 [status], [owned], [placed] 가
/// 달라진다. BE 가 상태를 미리 계산해 내려주므로 클라이언트는 enum 분기만 한다.
@immutable
class FurnitureShopItem {
  const FurnitureShopItem({
    required this.furnitureId,
    required this.code,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.imageUrl,
    required this.thumbnailUrl,
    required this.defaultX,
    required this.defaultY,
    required this.width,
    required this.height,
    required this.zIndex,
    required this.owned,
    required this.soldOut,
    required this.placed,
    required this.status,
  });

  final int furnitureId;
  final String code;
  final String name;
  final String description;
  final String category;
  final int price;
  final String imageUrl;
  final String thumbnailUrl;

  /// 방 좌표계 기준 기본 배치 좌표.
  final int defaultX;
  final int defaultY;
  final int width;
  final int height;

  /// 같은 카테고리 내 중첩 시 기본 z-order.
  final int zIndex;

  /// 사용자가 이미 구매한 가구.
  final bool owned;

  /// 더 이상 구매할 수 없는 가구 (이미 보유했거나 판매 중지).
  final bool soldOut;

  /// 방에 현재 배치된 상태.
  final bool placed;

  final FurnitureShopStatus status;
}

/// `POST /api/shop/furnitures/{furnitureId}/purchase` 결과.
///
/// 구매 후 새로 발급된 [userFurnitureId] 와 차감 후 [balance] 를 반환한다.
/// UI 는 이 값으로 즉시 잔액 표시를 갱신하고, 필요하면 listFurnitures 를 재조회.
@immutable
class FurniturePurchaseResult {
  const FurniturePurchaseResult({
    required this.furnitureId,
    required this.userFurnitureId,
    required this.owned,
    required this.soldOut,
    required this.balance,
  });

  final int furnitureId;
  final int userFurnitureId;
  final bool owned;
  final bool soldOut;
  final int balance;
}
