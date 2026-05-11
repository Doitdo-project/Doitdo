import 'package:flutter/foundation.dart';

/// 사용자가 구매해 보유 중인 가구 한 항목.
///
/// `GET /api/users/me/furnitures` 응답 항목을 정규화한 모델.
/// 동일 가구를 여러 번 구매했더라도 [userFurnitureId] 는 항목마다 고유.
/// [acquiredAt] 은 ISO-8601 파싱 실패 시 null.
@immutable
class UserFurnitureItem {
  const UserFurnitureItem({
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
  final DateTime? acquiredAt;
}
