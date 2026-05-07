import 'package:doitdo/domain/entities/user_furniture.dart';

/// `GET /api/users/me/furnitures` 응답 envelope 내부 `data`.
///
/// ```json
/// { "items": [ { ...UserFurnitureItemDto } ] }
/// ```
class UserFurnitureRespDto {
  const UserFurnitureRespDto({required this.items});

  final List<UserFurnitureItemDto> items;

  factory UserFurnitureRespDto.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    return UserFurnitureRespDto(
      items: raw is List
          ? raw
              .whereType<Map<String, dynamic>>()
              .map(UserFurnitureItemDto.fromJson)
              .toList(growable: false)
          : const [],
    );
  }

  List<UserFurnitureItem> toEntities() =>
      items.map((e) => e.toEntity()).toList(growable: false);
}

class UserFurnitureItemDto {
  const UserFurnitureItemDto({
    required this.userFurnitureId,
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
    required this.acquiredAt,
  });

  final int userFurnitureId;
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
  final String? acquiredAt;

  factory UserFurnitureItemDto.fromJson(Map<String, dynamic> json) {
    return UserFurnitureItemDto(
      userFurnitureId: (json['userFurnitureId'] as num?)?.toInt() ?? 0,
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
      acquiredAt: json['acquiredAt'] as String?,
    );
  }

  UserFurnitureItem toEntity() => UserFurnitureItem(
        userFurnitureId: userFurnitureId,
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
        acquiredAt: DateTime.tryParse(acquiredAt ?? ''),
      );
}
