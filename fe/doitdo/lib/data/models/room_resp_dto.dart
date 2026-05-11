import 'package:doitdo/domain/entities/room_placement.dart';

/// `GET /api/users/me/room` 또는 preview-room 응답 envelope 내부 `data`.
///
/// ```json
/// { "items": [ { ...RoomFurniturePlacementDto } ] }
/// ```
class RoomRespDto {
  const RoomRespDto({required this.items});

  final List<RoomFurniturePlacementDto> items;

  factory RoomRespDto.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    return RoomRespDto(
      items: raw is List
          ? raw
              .whereType<Map<String, dynamic>>()
              .map(RoomFurniturePlacementDto.fromJson)
              .toList(growable: false)
          : const [],
    );
  }

  List<RoomFurniturePlacement> toEntities() =>
      items.map((e) => e.toEntity()).toList(growable: false);
}

/// 방에 배치된 가구 한 개. `place`/`update` 응답으로도 직접 사용된다.
class RoomFurniturePlacementDto {
  const RoomFurniturePlacementDto({
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

  /// preview 응답에서는 null 로 내려온다.
  final int? placementId;

  /// preview 응답에서는 null 로 내려온다.
  final int? userFurnitureId;

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
  final bool preview;

  factory RoomFurniturePlacementDto.fromJson(Map<String, dynamic> json) {
    return RoomFurniturePlacementDto(
      placementId: (json['placementId'] as num?)?.toInt(),
      userFurnitureId: (json['userFurnitureId'] as num?)?.toInt(),
      furnitureId: (json['furnitureId'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? '',
      category: (json['category'] as String?) ?? '',
      imageUrl: (json['imageUrl'] as String?) ?? '',
      x: (json['x'] as num?)?.toInt() ?? 0,
      y: (json['y'] as num?)?.toInt() ?? 0,
      width: (json['width'] as num?)?.toInt() ?? 0,
      height: (json['height'] as num?)?.toInt() ?? 0,
      zIndex: (json['zIndex'] as num?)?.toInt() ?? 0,
      rotation: (json['rotation'] as num?)?.toInt() ?? 0,
      preview: (json['preview'] as bool?) ?? false,
    );
  }

  RoomFurniturePlacement toEntity() => RoomFurniturePlacement(
        placementId: placementId,
        userFurnitureId: userFurnitureId,
        furnitureId: furnitureId,
        name: name,
        category: category,
        imageUrl: imageUrl,
        x: x,
        y: y,
        width: width,
        height: height,
        zIndex: zIndex,
        rotation: rotation,
        preview: preview,
      );
}
