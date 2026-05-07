import 'package:flutter/foundation.dart';

import 'package:doitdo/presentation/pages/shop/shop_state.dart';

/// 카드 / 미리보기 영역 안에서 가구 한 점이 차지할 자리.
///
/// 모든 값은 부모 컨테이너 width / height 에 대한 비율(0~1) 이다 — 부모 크기가
/// 다라져도 (홈 카드 vs 상점 미리보기) 같은 구도가 유지된다.
/// `left`/`right`, `top`/`bottom` 은 한 쌍씩만 채운다.
@immutable
class RoomFurnitureSlot {
  const RoomFurnitureSlot({
    this.left,
    this.right,
    this.top,
    this.bottom,
    required this.width,
    required this.height,
  });

  final double? left;
  final double? right;
  final double? top;
  final double? bottom;
  final double width;
  final double height;
}

/// 다마고치 홈 캐릭터 카드(`RoomLayer`)와 상점 진입 시 방 미리보기
/// (`ShopRoomPreview`)가 공유하는 카테고리별 슬롯 맵.
///
/// `BACKGROUND` 카테고리는 별도 처리(컨테이너 꽉 채우는 베이스) 라 여기 없다.
/// 매칭 슬롯이 없는 카테고리는 [kRoomFurnitureFallbackSlot] 으로 대피.
const Map<ShopCategory, RoomFurnitureSlot> kRoomFurnitureSlots = {
  ShopCategory.bed:      RoomFurnitureSlot(left: 0.00, bottom: 0.00, width: 0.26, height: 0.34),
  ShopCategory.plant:    RoomFurnitureSlot(right: 0.04, bottom: 0.04, width: 0.16, height: 0.28),
  ShopCategory.rug:      RoomFurnitureSlot(left: 0.36, bottom: 0.12, width: 0.30, height: 0.28),
  ShopCategory.desk:     RoomFurnitureSlot(left: 0.04, top: 0.32, width: 0.28, height: 0.30),
  ShopCategory.tv:       RoomFurnitureSlot(right: 0.0, top: 0.30, width: 0.28, height: 0.28),
  ShopCategory.window:   RoomFurnitureSlot(right: 0.30, top: 0.08, width: 0.28, height: 0.28),
  ShopCategory.clock:    RoomFurnitureSlot(left: 0.08, top: 0.12, width: 0.12, height: 0.12),
};

const RoomFurnitureSlot kRoomFurnitureFallbackSlot =
    RoomFurnitureSlot(left: 0.30, top: 0.35, width: 0.30, height: 0.30);
