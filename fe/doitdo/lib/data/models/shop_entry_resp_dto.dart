import 'package:doitdo/data/models/furniture_shop_resp_dto.dart';
import 'package:doitdo/data/models/room_resp_dto.dart';
import 'package:doitdo/domain/entities/shop_entry.dart';

/// `GET /api/shop/entry` 응답 envelope 내부 `data`.
///
/// ```json
/// {
///   "furnitures": { "items": [ ... ] },
///   "room":       { "items": [ ... ] }
/// }
/// ```
class ShopEntryRespDto {
  const ShopEntryRespDto({
    required this.furnitures,
    required this.room,
  });

  final FurnitureShopRespDto furnitures;
  final RoomRespDto room;

  factory ShopEntryRespDto.fromJson(Map<String, dynamic> json) {
    final furnituresJson = json['furnitures'];
    final roomJson = json['room'];
    return ShopEntryRespDto(
      furnitures: furnituresJson is Map<String, dynamic>
          ? FurnitureShopRespDto.fromJson(furnituresJson)
          : const FurnitureShopRespDto(items: []),
      room: roomJson is Map<String, dynamic>
          ? RoomRespDto.fromJson(roomJson)
          : const RoomRespDto(items: []),
    );
  }

  ShopEntry toEntity() => ShopEntry(
        furnitures: furnitures.toEntities(),
        room: room.toEntities(),
      );
}
