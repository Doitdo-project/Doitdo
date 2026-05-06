import 'package:flutter/foundation.dart';

import 'package:doitdo/domain/entities/room_placement.dart';
import 'package:doitdo/domain/entities/shop_furniture.dart';

/// `GET /api/shop/entry` 합본 응답.
///
/// 상점 진입 시 가구 목록과 현재 내 방 배치 정보를 한 번에 받기 위해 BE 가
/// 묶어서 내려주는 페이로드. 두 필드 모두 별도 엔드포인트로도 조회 가능하지만,
/// 첫 진입에서는 round-trip 한 번으로 끝내는 용도.
@immutable
class ShopEntry {
  const ShopEntry({
    required this.furnitures,
    required this.room,
  });

  final List<FurnitureShopItem> furnitures;
  final List<RoomFurniturePlacement> room;
}
