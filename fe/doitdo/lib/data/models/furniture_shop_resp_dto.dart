import 'package:doitdo/domain/entities/shop_furniture.dart';

/// `GET /api/shop/furnitures` 응답 envelope 내부 `data`.
///
/// ```json
/// { "items": [ { ...FurnitureShopItemDto } ] }
/// ```
class FurnitureShopRespDto {
  const FurnitureShopRespDto({required this.items});

  final List<FurnitureShopItemDto> items;

  factory FurnitureShopRespDto.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    return FurnitureShopRespDto(
      items: raw is List
          ? raw
              .whereType<Map<String, dynamic>>()
              .map(FurnitureShopItemDto.fromJson)
              .toList(growable: false)
          : const [],
    );
  }

  List<FurnitureShopItem> toEntities() =>
      items.map((e) => e.toEntity()).toList(growable: false);
}

class FurnitureShopItemDto {
  const FurnitureShopItemDto({
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
  final int defaultX;
  final int defaultY;
  final int width;
  final int height;
  final int zIndex;
  final bool owned;
  final bool soldOut;
  final bool placed;
  final String status;

  factory FurnitureShopItemDto.fromJson(Map<String, dynamic> json) {
    return FurnitureShopItemDto(
      furnitureId: (json['furnitureId'] as num?)?.toInt() ?? 0,
      code: (json['code'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      category: (json['category'] as String?) ?? '',
      price: (json['price'] as num?)?.toInt() ?? 0,
      imageUrl: (json['imageUrl'] as String?) ?? '',
      thumbnailUrl: (json['thumbnailUrl'] as String?) ?? '',
      defaultX: (json['defaultX'] as num?)?.toInt() ?? 0,
      defaultY: (json['defaultY'] as num?)?.toInt() ?? 0,
      width: (json['width'] as num?)?.toInt() ?? 0,
      height: (json['height'] as num?)?.toInt() ?? 0,
      zIndex: (json['zIndex'] as num?)?.toInt() ?? 0,
      owned: (json['owned'] as bool?) ?? false,
      soldOut: (json['soldOut'] as bool?) ?? false,
      placed: (json['placed'] as bool?) ?? false,
      status: (json['status'] as String?) ?? '',
    );
  }

  FurnitureShopItem toEntity() => FurnitureShopItem(
        furnitureId: furnitureId,
        code: code,
        name: name,
        description: description,
        category: category,
        price: price,
        imageUrl: imageUrl,
        thumbnailUrl: thumbnailUrl,
        defaultX: defaultX,
        defaultY: defaultY,
        width: width,
        height: height,
        zIndex: zIndex,
        owned: owned,
        soldOut: soldOut,
        placed: placed,
        status: FurnitureShopStatus.fromRaw(status),
      );
}
