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
  ShopCategory.bed:      RoomFurnitureSlot(left: 0.00, bottom: 0.12, width: 0.30, height: 0.38),
  ShopCategory.plant:    RoomFurnitureSlot(right: 0.04, bottom: 0.16, width: 0.14, height: 0.20),
  ShopCategory.rug:      RoomFurnitureSlot(left: 0.36, bottom: 0.14, width: 0.28, height: 0.28),
  ShopCategory.desk:     RoomFurnitureSlot(left: 0.06, top: 0.26, width: 0.30, height: 0.30),
  ShopCategory.tv:       RoomFurnitureSlot(right: 0.02, top: 0.26, width: 0.26, height: 0.26),
  ShopCategory.window:   RoomFurnitureSlot(right: 0.30, top: 0.00, width: 0.28, height: 0.28),
  ShopCategory.clock:    RoomFurnitureSlot(left: 0.08, top: 0.10, width: 0.12, height: 0.12),
};

const RoomFurnitureSlot kRoomFurnitureFallbackSlot =
    RoomFurnitureSlot(left: 0.30, top: 0.35, width: 0.30, height: 0.30);

/// 룸 카드(`RoomLayer`) 안 가구 캔버스의 고정 종횡비(width / height).
/// 디바이스 / 상태바 인셋이 달라져도 가구 배치 비율이 동일하게 보이도록 잠그는
/// 기준점. 디자인(375 × 300) 에서 따왔다.
const double kRoomCanvasAspect = 375 / 300;

/// 상점 미리보기(`ShopRoomPreview`) 안 가구 캔버스의 고정 종횡비.
/// 디자인 기준 (페이지 가로 padding 24×2 제외 = 327) × 180 에서 따왔다.
const double kShopPreviewCanvasAspect = 327 / 180;

/// 부모 컨테이너 [parentWidth] × [parentHeight] 안에 [aspect] AR 의 가구 캔버스를
/// **하단 anchor + 가로 가운데 정렬** 로 배치할 때의 크기 / 오프셋.
/// 하단 anchor 인 이유: 캐릭터가 카드 하단에 서있는 구조와 정렬되도록 가구 바닥선이
/// 모든 기기에서 카드 하단으로부터 동일한 비율에 위치해야 자연스럽다. 남는 여백은
/// 카드 상단 — 풀블리드 배경이 깔려있어 시각적으로 잘 드러나지 않는다.
({double width, double height, double offsetX, double offsetY}) computeRoomCanvasLayout({
  required double parentWidth,
  required double parentHeight,
  required double aspect,
}) {
  final double w;
  final double h;
  if (parentWidth / parentHeight > aspect) {
    // 카드 AR 이 캔버스보다 더 넓다 → 높이가 한계, 가로에 여백 발생.
    h = parentHeight;
    w = parentHeight * aspect;
  } else {
    // 카드 AR 이 캔버스보다 더 좁다 → 가로가 한계, 상단에 여백 발생.
    w = parentWidth;
    h = parentWidth / aspect;
  }
  return (
    width: w,
    height: h,
    offsetX: (parentWidth - w) / 2,
    offsetY: parentHeight - h,
  );
}
