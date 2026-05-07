import 'package:doitdo/domain/entities/shop_furniture.dart';

/// `POST /api/shop/furnitures/{furnitureId}/purchase` 응답 envelope 내부 `data`.
///
/// ```json
/// {
///   "furnitureId": 0,
///   "userFurnitureId": 0,
///   "owned": true,
///   "soldOut": true,
///   "balance": 0
/// }
/// ```
class PurchaseFurnitureRespDto {
  const PurchaseFurnitureRespDto({
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

  factory PurchaseFurnitureRespDto.fromJson(Map<String, dynamic> json) {
    return PurchaseFurnitureRespDto(
      furnitureId: (json['furnitureId'] as num?)?.toInt() ?? 0,
      userFurnitureId: (json['userFurnitureId'] as num?)?.toInt() ?? 0,
      owned: (json['owned'] as bool?) ?? false,
      soldOut: (json['soldOut'] as bool?) ?? false,
      balance: (json['balance'] as num?)?.toInt() ?? 0,
    );
  }

  FurniturePurchaseResult toEntity() => FurniturePurchaseResult(
        furnitureId: furnitureId,
        userFurnitureId: userFurnitureId,
        owned: owned,
        soldOut: soldOut,
        balance: balance,
      );
}
