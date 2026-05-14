import 'package:flutter/foundation.dart';

/// 상점에서 선택 가능한 가구 "테마" 한 항목.
///
/// 테마 = 같은 컨셉(가을/벚꽃/사이버 등) 으로 묶인 여러 카테고리의 가구 세트.
/// 카드 자체는 메타 정보만 보여주고, 실제 미리보기는
/// `GET /api/shop/themes/{themeCode}/preview-room` 호출로 받아 방 영역에 합성한다.
@immutable
class FurnitureTheme {
  const FurnitureTheme({
    required this.themeCode,
    required this.themeName,
    required this.thumbnailUrl,
    required this.furnitureCount,
  });

  /// 테마 식별자. preview-room 호출 path 에 그대로 들어간다. 예: `AUTUMN`.
  final String themeCode;

  /// 사용자에게 보여줄 이름. 예: `가을`.
  final String themeName;

  /// 카드 썸네일. 비어 있으면 카테고리 폴백 아이콘으로 그린다.
  final String thumbnailUrl;

  /// 테마에 묶인 활성 가구 개수 — "X종 가구" 보조 텍스트로 표시.
  final int furnitureCount;
}
