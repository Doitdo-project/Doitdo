/// 카테고리 API DTO.
///
/// swagger `/api/categories` 스펙 기준:
/// - CategoryResp     : { categoryId, categoryName, colorId, colorHex }
/// - CategoryListResp : { items: List<CategoryResp> }
///
/// swagger `/api/palettes` 스펙 기준:
/// - PaletteResp     : { paletteId, paletteName, colors: List<String> }
/// - PaletteListResp : List<PaletteResp> 를 data 배열로 직접 반환

import 'package:flutter/material.dart';

class CategoryResp {
  const CategoryResp({
    required this.categoryId,
    required this.categoryName,
    required this.colorId,
    required this.colorHex,
  });

  final int categoryId;
  final String categoryName;
  final int colorId;

  /// 서버가 내려주는 hex 색상 문자열 (예: "#A8C5E8").
  /// 이 값을 color 게터로 변환해 UI 에서 직접 사용한다.
  final String colorHex;

  /// colorHex → Flutter Color 변환.
  Color get color => _hexToColor(colorHex);

  factory CategoryResp.fromJson(Map<String, dynamic> json) => CategoryResp(
        categoryId: (json['categoryId'] as num).toInt(),
        categoryName: json['categoryName'] as String,
        colorId: (json['colorId'] as num).toInt(),
        colorHex: (json['colorHex'] as String?) ?? '#CCCCCC',
      );
}

class CategoryListResp {
  const CategoryListResp({required this.items});

  final List<CategoryResp> items;

  factory CategoryListResp.fromJson(Map<String, dynamic> json) =>
      CategoryListResp(
        items: (json['items'] as List<dynamic>)
            .map((e) => CategoryResp.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

// ─── 팔레트 ──────────────────────────────────────────────────────

class PaletteResp {
  const PaletteResp({
    required this.paletteId,
    required this.paletteName,
    required this.colors,
  });

  final int paletteId;
  final String paletteName;

  /// 서버가 내려주는 hex 문자열 목록 (예: ["#A8C5E8", "#F2B23A", ...]).
  final List<String> colors;

  factory PaletteResp.fromJson(Map<String, dynamic> json) => PaletteResp(
        paletteId: (json['paletteId'] as num).toInt(),
        paletteName: json['paletteName'] as String,
        colors: (json['colors'] as List<dynamic>).cast<String>(),
      );
}

/// /api/palettes 는 data 가 List 이므로 래퍼로 감싼다.
/// fromJson 은 Object? 를 받아 List 로 캐스팅한다.
class PaletteListResp {
  const PaletteListResp({required this.items});

  final List<PaletteResp> items;

  static PaletteListResp fromJson(Object? json) {
    final list = json as List<dynamic>;
    return PaletteListResp(
      items: list
          .map((e) => PaletteResp.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ─── hex 파싱 유틸 ───────────────────────────────────────────────

Color _hexToColor(String hex) {
  final cleaned = hex.replaceAll('#', '');
  if (cleaned.length == 6) {
    return Color(int.parse('FF$cleaned', radix: 16));
  }
  if (cleaned.length == 8) {
    return Color(int.parse(cleaned, radix: 16));
  }
  return const Color(0xFFCCCCCC);
}

/// 팔레트 hex 문자열 → Color 변환 헬퍼 (외부에서 직접 필요할 때).
Color hexToColor(String hex) => _hexToColor(hex);
