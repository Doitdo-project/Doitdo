import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:doitdo/core/theme/app_colors.dart';
import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/pages/shop/shop_state.dart';

/// 상점 상단의 "방 미리보기" 영역.
///
/// 실제 가구 에셋이 들어오기 전 단계라, 카테고리별 Material 아이콘으로
/// "벽(상단) — 바닥(하단 체커 패턴)" 구도를 흉내낸 플레이스홀더.
/// 벽지/타일은 배경에 톤만 입히고, 나머지는 작은 카드로 표시한다.
class ShopRoomPreview extends StatelessWidget {
  const ShopRoomPreview({super.key, required this.items});

  /// 방에 표시할 아이템들. 호출자가 placed + 미리보기 토글을 합성해서 넘긴다.
  final List<ShopItem> items;

  static const _wallCategories = {
    ShopCategory.window,
    ShopCategory.clock,
    ShopCategory.tv,
  };
  static const _floorCategories = {
    ShopCategory.bed,
    ShopCategory.desk,
    ShopCategory.plant,
    ShopCategory.carpet,
    ShopCategory.closet,
    ShopCategory.etc,
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final wallpaper = _findFirst(ShopCategory.wallpaper);
    final tile = _findFirst(ShopCategory.tile);
    final wallItems = items.where((it) => _wallCategories.contains(it.category));
    final floorItems = items.where((it) => _floorCategories.contains(it.category));

    return ClipRRect(
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        height: 180.h,
        decoration: BoxDecoration(
          color: colors.streakCardBg,
          border: Border.all(color: colors.border),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Column(
          children: [
            Expanded(
              flex: 5,
              child: _Wall(
                wallpaper: wallpaper,
                items: wallItems.toList(growable: false),
              ),
            ),
            Expanded(
              flex: 4,
              child: _Floor(
                tile: tile,
                items: floorItems.toList(growable: false),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ShopItem? _findFirst(ShopCategory category) {
    for (final it in items) {
      if (it.category == category) return it;
    }
    return null;
  }
}

class _Wall extends StatelessWidget {
  const _Wall({required this.wallpaper, required this.items});

  final ShopItem? wallpaper;
  final List<ShopItem> items;

  @override
  Widget build(BuildContext context) {
    // 배치된 벽지가 있으면 톤을 살짝 입혀 "벽지 적용된 느낌" 만 표시.
    final tint = wallpaper == null
        ? AppColors.streakBg
        : Color.alphaBlend(
            _categoryAccent(wallpaper!.category).withValues(alpha: 0.18),
            AppColors.streakBg,
          );

    return Container(
      color: tint,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          for (final it in items) ...[
            _PlacedChip(item: it, onWall: true),
            SizedBox(width: 10.w),
          ],
        ],
      ),
    );
  }
}

class _Floor extends StatelessWidget {
  const _Floor({required this.tile, required this.items});

  final ShopItem? tile;
  final List<ShopItem> items;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: CustomPaint(painter: _CheckerPainter(tile: tile))),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (final it in items) _PlacedChip(item: it, onWall: false),
            ],
          ),
        ),
      ],
    );
  }
}

class _CheckerPainter extends CustomPainter {
  _CheckerPainter({required this.tile});

  final ShopItem? tile;

  @override
  void paint(Canvas canvas, Size size) {
    const cell = 18.0;
    final base = tile == null
        ? const Color(0xFFE9D7BF)
        : Color.alphaBlend(
            _categoryAccent(tile!.category).withValues(alpha: 0.25),
            const Color(0xFFE9D7BF),
          );
    final dark = Color.alphaBlend(Colors.black.withValues(alpha: 0.06), base);

    final basePaint = Paint()..color = base;
    final darkPaint = Paint()..color = dark;
    canvas.drawRect(Offset.zero & size, basePaint);

    final cols = (size.width / cell).ceil();
    final rows = (size.height / cell).ceil();
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if ((r + c).isOdd) continue;
        canvas.drawRect(
          Rect.fromLTWH(c * cell, r * cell, cell, cell),
          darkPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CheckerPainter oldDelegate) =>
      oldDelegate.tile?.id != tile?.id;
}

class _PlacedChip extends StatelessWidget {
  const _PlacedChip({required this.item, required this.onWall});

  final ShopItem item;
  final bool onWall;

  @override
  Widget build(BuildContext context) {
    final accent = _categoryAccent(item.category);
    final size = onWall ? 32.w : 40.w;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Icon(item.category.icon, size: size * 0.6, color: accent),
    );
  }
}

/// 더미 일러스트가 들어오기 전까지 카테고리별 톤을 분리해서 보여주기 위한 색.
/// 실제 에셋이 들어오면 이 함수와 _PlacedChip 은 통째로 이미지로 교체된다.
Color _categoryAccent(ShopCategory category) {
  switch (category) {
    case ShopCategory.wallpaper:
      return const Color(0xFFB69BD8);
    case ShopCategory.tile:
      return const Color(0xFFC9A47A);
    case ShopCategory.bed:
      return const Color(0xFFE48BA0);
    case ShopCategory.desk:
      return const Color(0xFF8E6E4A);
    case ShopCategory.window:
      return const Color(0xFF8FB3D4);
    case ShopCategory.clock:
      return const Color(0xFF6E8E7B);
    case ShopCategory.tv:
      return const Color(0xFF5A6470);
    case ShopCategory.plant:
      return const Color(0xFF6FA86F);
    case ShopCategory.carpet:
      return const Color(0xFFD08AA0);
    case ShopCategory.closet:
      return const Color(0xFF8B7E66);
    case ShopCategory.etc:
      return AppColors.shopText;
  }
}

/// 외부 위젯에서도 카테고리 톤을 동일하게 쓸 수 있도록 노출.
Color shopCategoryAccent(ShopCategory category) => _categoryAccent(category);

class ShopRoomPreviewEmpty extends StatelessWidget {
  const ShopRoomPreviewEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      height: 180.h,
      decoration: BoxDecoration(
        color: colors.streakCardBg,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: colors.border),
      ),
      alignment: Alignment.center,
      child: Text(
        '아직 배치된 가구가 없어요',
        style: AppTextStyles.bodySmall.copyWith(color: colors.textHint),
      ),
    );
  }
}
