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
  });

  final String themeCode;
  final String themeName;
  final String thumbnailUrl;
  final int furnitureCount;

  factory FurnitureThemeDto.fromJson(Map<String, dynamic> json) {
    return FurnitureThemeDto(
      themeCode: (json['themeCode'] as String?) ?? '',
      themeName: (json['themeName'] as String?) ?? '',
      thumbnailUrl: (json['thumbnailUrl'] as String?) ?? '',
      furnitureCount: (json['furnitureCount'] as num?)?.toInt() ?? 0,
    );
  }

  FurnitureTheme toEntity() => FurnitureTheme(
        themeCode: themeCode,
        themeName: themeName,
        thumbnailUrl: thumbnailUrl,
        furnitureCount: furnitureCount,
      );
}
