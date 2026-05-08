import 'package:flutter/foundation.dart';

/// 사용자 방에 배치된 가구 한 개.
///
/// 미리보기 응답에서는 [placementId], [userFurnitureId] 가 null 이고
/// [preview] 가 true 다 — UI 는 이를 보고 "임시 배치" 표시를 한다.
/// 실제 저장된 배치는 [placementId] 와 [userFurnitureId] 가 모두 채워져 있다.
@immutable
class RoomFurniturePlacement {
  const RoomFurniturePlacement({
    required this.placementId,
    required this.userFurnitureId,
    required this.furnitureId,
    required this.name,
    required this.category,
    required this.imageUrl,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.zIndex,
    required this.rotation,
    required this.preview,
  });

  /// 저장된 배치 ID. preview 응답에서는 null.
  final int? placementId;

  /// 보유 가구 인스턴스 ID. preview 응답에서는 null.
  final int? userFurnitureId;

  /// 가구 마스터 ID.
  final int furnitureId;

  final String name;
  final String category;
  final String imageUrl;

  final int x;
  final int y;
  final int width;
  final int height;
  final int zIndex;
  final int rotation;

  /// preview-room 응답으로 들어온 임시 배치인지.
  final bool preview;
}
