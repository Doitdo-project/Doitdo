import 'package:doitdo/domain/entities/furniture_theme.dart';

/// `GET /api/shop/themes` 응답 envelope 내부 `data`.
///
/// ```json
/// { "items": [ { ...FurnitureThemeDto } ] }
/// ```
class FurnitureThemeListRespDto {
  const FurnitureThemeListRespDto({required this.items});

  final List<FurnitureThemeDto> items;

  factory FurnitureThemeListRespDto.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    return FurnitureThemeListRespDto(
      items: raw is List
          ? raw
              .whereType<Map<String, dynamic>>()
              .map(FurnitureThemeDto.fromJson)
              .toList(growable: false)
          : const [],
    );
  }

  List<FurnitureTheme> toEntities() =>
      items.map((e) => e.toEntity()).toList(growable: false);
}

class FurnitureThemeDto {
  const FurnitureThemeDto({
    required this.themeCode,
    required this.themeName,
    required this.thumbnailUrl,
    required this.furnitureCount,
    required this.ownedCount,
    required this.totalPrice,
    required this.purchasePrice,
    required this.alreadyOwned,
    required this.furnitures,
  });

  final String themeCode;
  final String themeName;
  final String thumbnailUrl;
  final int furnitureCount;
  final int ownedCount;
  final int totalPrice;
  final int purchasePrice;
  final bool alreadyOwned;
  final List<ThemeFurnitureDto> furnitures;

  factory FurnitureThemeDto.fromJson(Map<String, dynamic> json) {
    final rawFurnitures = json['furnitures'];
    return FurnitureThemeDto(
      themeCode: (json['themeCode'] as String?) ?? '',
      themeName: (json['themeName'] as String?) ?? '',
      thumbnailUrl: (json['thumbnailUrl'] as String?) ?? '',
      furnitureCount: (json['furnitureCount'] as num?)?.toInt() ?? 0,
      ownedCount: (json['ownedCount'] as num?)?.toInt() ?? 0,
      totalPrice: (json['totalPrice'] as num?)?.toInt() ?? 0,
      purchasePrice: (json['purchasePrice'] as num?)?.toInt() ?? 0,
      alreadyOwned: (json['alreadyOwned'] as bool?) ?? false,
      furnitures: rawFurnitures is List
          ? rawFurnitures
              .whereType<Map<String, dynamic>>()
              .map(ThemeFurnitureDto.fromJson)
              .toList(growable: false)
          : const [],
    );
  }

  FurnitureTheme toEntity() => FurnitureTheme(
        themeCode: themeCode,
        themeName: themeName,
        thumbnailUrl: thumbnailUrl,
        furnitureCount: furnitureCount,
        ownedCount: ownedCount,
        totalPrice: totalPrice,
        purchasePrice: purchasePrice,
        alreadyOwned: alreadyOwned,
        furnitures:
            furnitures.map((e) => e.toEntity()).toList(growable: false),
      );
}

class ThemeFurnitureDto {
  const ThemeFurnitureDto({
    required this.furnitureId,
    required this.name,
    required this.category,
    required this.price,
    required this.imageUrl,
    required this.owned,
  });

  final int furnitureId;
  final String name;
  final String category;
  final int price;
  final String imageUrl;
  final bool owned;

  factory ThemeFurnitureDto.fromJson(Map<String, dynamic> json) {
    // listThemes 응답은 `thumbnailUrl` 로 보내고 카테고리 필드는 누락된 상태
    // (BE MR !285 시점). preview-room 등 다른 응답은 `imageUrl`/`category` 를
    // 보내므로 두 키를 다 받아서 어느 쪽에서 와도 안전하게 매핑한다.
    final thumb = json['thumbnailUrl'] as String?;
    final image = json['imageUrl'] as String?;
    return ThemeFurnitureDto(
      furnitureId: (json['furnitureId'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? '',
      category: (json['category'] as String?) ?? '',
      price: (json['price'] as num?)?.toInt() ?? 0,
      imageUrl: thumb?.isNotEmpty == true ? thumb! : (image ?? ''),
      owned: (json['owned'] as bool?) ?? false,
    );
  }

  ThemeFurniture toEntity() => ThemeFurniture(
        furnitureId: furnitureId,
        name: name,
        category: category,
        price: price,
        imageUrl: imageUrl,
        owned: owned,
      );
}

/// `POST /api/shop/themes/{themeCode}/purchase` 응답 envelope 내부 `data`.
class ThemePurchaseRespDto {
  const ThemePurchaseRespDto({
    required this.themeCode,
    required this.themeName,
    required this.purchasedCount,
    required this.skippedOwnedCount,
    required this.totalPaid,
    required this.balance,
  });

  final String themeCode;
  final String themeName;
  final int purchasedCount;
  final int skippedOwnedCount;
  final int totalPaid;
  final int balance;

  factory ThemePurchaseRespDto.fromJson(Map<String, dynamic> json) {
    return ThemePurchaseRespDto(
      themeCode: (json['themeCode'] as String?) ?? '',
      themeName: (json['themeName'] as String?) ?? '',
      purchasedCount: (json['purchasedCount'] as num?)?.toInt() ?? 0,
      skippedOwnedCount: (json['skippedOwnedCount'] as num?)?.toInt() ?? 0,
      totalPaid: (json['totalPaid'] as num?)?.toInt() ?? 0,
      balance: (json['balance'] as num?)?.toInt() ?? 0,
    );
  }

  ThemePurchaseResult toEntity() => ThemePurchaseResult(
        themeCode: themeCode,
        themeName: themeName,
        purchasedCount: purchasedCount,
        skippedOwnedCount: skippedOwnedCount,
        totalPaid: totalPaid,
        balance: balance,
      );
}

/// `POST /api/users/me/room/themes/{themeCode}/placements` 응답 envelope 내부 `data`.
///
/// items[] 는 가구 placement 상세를 담지만, 클라이언트는 [placedCount] 와 메타만
/// 사용하고 실제 방 상태 갱신은 별도 room 재조회로 처리한다 — Item 매핑이 ShopItem
/// 으로 다시 합쳐져야 해서 path 가 길어지기 때문.
class ThemePlacementRespDto {
  const ThemePlacementRespDto({
    required this.themeCode,
    required this.themeName,
    required this.placedCount,
  });

  final String themeCode;
  final String themeName;
  final int placedCount;

  factory ThemePlacementRespDto.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final placedFromItems =
        rawItems is List ? rawItems.length : null;
    return ThemePlacementRespDto(
      themeCode: (json['themeCode'] as String?) ?? '',
      themeName: (json['themeName'] as String?) ?? '',
      // placedCount 가 누락된 응답에서도 items 길이로 폴백.
      placedCount: (json['placedCount'] as num?)?.toInt() ??
          placedFromItems ??
          0,
    );
  }

  ThemePlacementResult toEntity() => ThemePlacementResult(
        themeCode: themeCode,
        themeName: themeName,
        placedCount: placedCount,
      );
}
