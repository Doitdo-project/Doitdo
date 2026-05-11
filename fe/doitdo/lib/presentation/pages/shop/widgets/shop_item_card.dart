import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:doitdo/core/theme/app_colors.dart';
import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/pages/shop/shop_state.dart';
import 'package:doitdo/presentation/pages/shop/widgets/coin_icon.dart';
import 'package:doitdo/presentation/pages/shop/widgets/shop_room_preview.dart'
    show shopCategoryAccent;

/// 상품 그리드 셀.
///
/// 카드 하단 액션은 보유 상태별로 한 개만 노출 (full width):
/// - 미보유: [구매]
/// - 보유  : [배치]
/// - 배치중: [해제]
///
/// 미리보기는 별도 버튼 없이 **카드 자체 탭**으로 토글한다. 배치중 아이템도 토글
/// 가능 — 방 미리보기 영역은 동일하게 보이지만 (preview == placed 라 합성 결과
/// 변화 없음) 카드 highlight + "미리보기" 뱃지로 사용자가 어떤 항목을 보고 있는지
/// 시각적으로 알 수 있게 한다.
/// 미리보기 중인 카드는 border 가 카테고리 accent 톤으로 강조되고 좌하단 뱃지가 뜬다.
class ShopItemCard extends StatelessWidget {
  const ShopItemCard({
    super.key,
    required this.item,
    this.isPreviewing = false,
    this.onTapPreview,
    this.onTapBuy,
    this.onTapPlace,
    this.onTapUnplace,
  });

  final ShopItem item;
  final bool isPreviewing;
  final VoidCallback? onTapPreview;
  final VoidCallback? onTapBuy;
  final VoidCallback? onTapPlace;
  final VoidCallback? onTapUnplace;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isPlaced = item.status == ItemStatus.placed;
    final accent = shopCategoryAccent(item.category);

    // 미리보기 활성 = 카테고리 accent / 배치중 = brand orange / 평상시 = 기본 border.
    final borderColor = isPreviewing
        ? accent
        : isPlaced
            ? AppColors.streakCheck.withValues(alpha: 0.6)
            : colors.border;
    final borderWidth = (isPreviewing || isPlaced) ? 1.5 : 1.0;

    return GestureDetector(
      // 카드 빈 영역 탭 → 미리보기 토글. 내부 액션 버튼은 자체 onPressed 가 이벤트를
      // consume 하므로 여기까지 전파되지 않는다.
      onTap: onTapPreview,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: isPlaced ? AppColors.streakBg : colors.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        padding: EdgeInsets.all(10.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _Preview(item: item, isPreviewing: isPreviewing)),
            SizedBox(height: 8.h),
            Text(
              item.name,
              style: AppTextStyles.bodyMedium.copyWith(color: colors.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4.h),
            _StatusOrPriceLine(item: item),
            SizedBox(height: 8.h),
            _ActionButton(
              item: item,
              onTapBuy: onTapBuy,
              onTapPlace: onTapPlace,
              onTapUnplace: onTapUnplace,
            ),
          ],
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.item, required this.isPreviewing});

  final ShopItem item;
  final bool isPreviewing;

  @override
  Widget build(BuildContext context) {
    final accent = shopCategoryAccent(item.category);

    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12.r),
            ),
            alignment: Alignment.center,
            padding: EdgeInsets.all(6.w),
            child: item.imageUrl.isEmpty
                ? Icon(item.category.icon, size: 36.sp, color: accent)
                : Image.network(
                    item.imageUrl,
                    width: 64.w,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (_, _, _) =>
                        Icon(item.category.icon, size: 36.sp, color: accent),
                  ),
          ),
        ),
        if (item.status == ItemStatus.placed)
          Positioned(
            top: 6.h,
            left: 6.w,
            child: const _StatusBadge.placed(),
          )
        else if (item.status == ItemStatus.owned)
          Positioned(
            top: 6.h,
            left: 6.w,
            child: const _StatusBadge.owned(),
          ),
        if (isPreviewing)
          Positioned(
            bottom: 6.h,
            left: 6.w,
            child: const _PreviewingBadge(),
          ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge.placed()
      : label = '배치중',
        bg = AppColors.streakCheck,
        fg = Colors.white;

  const _StatusBadge.owned()
      : label = '보유',
        bg = AppColors.chipSelectedBg,
        fg = AppColors.chipSelectedText;

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// 카드 탭으로 미리보기 토글된 상태를 알리는 좌하단 뱃지.
class _PreviewingBadge extends StatelessWidget {
  const _PreviewingBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppColors.streakCheck,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.visibility_rounded, size: 10.sp, color: Colors.white),
          SizedBox(width: 3.w),
          Text(
            '미리보기',
            style: AppTextStyles.labelSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusOrPriceLine extends StatelessWidget {
  const _StatusOrPriceLine({required this.item});

  final ShopItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (item.status == ItemStatus.notOwned) {
      return Row(
        children: [
          CoinIcon(size: 16.sp),
          SizedBox(width: 4.w),
          Text(
            _formatCoins(item.price),
            style: AppTextStyles.labelMedium.copyWith(color: colors.textSecondary),
          ),
        ],
      );
    }
    return Text(
      '보유 중',
      style: AppTextStyles.bodySmall.copyWith(color: colors.textSecondary),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.item,
    required this.onTapBuy,
    required this.onTapPlace,
    required this.onTapUnplace,
  });

  final ShopItem item;
  final VoidCallback? onTapBuy;
  final VoidCallback? onTapPlace;
  final VoidCallback? onTapUnplace;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final (label, bg, fg, onTap) = switch (item.status) {
      ItemStatus.notOwned => (
        '구매',
        AppColors.streakCheck,
        Colors.white,
        onTapBuy,
      ),
      ItemStatus.owned => (
        '배치',
        AppColors.streakBg,
        AppColors.streakCheck,
        onTapPlace,
      ),
      ItemStatus.placed => (
        '해제',
        colors.surface,
        colors.textSecondary,
        onTapUnplace,
      ),
    };

    return SizedBox(
      width: double.infinity,
      height: 32.h,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
            side: item.status == ItemStatus.placed
                ? BorderSide(color: colors.border)
                : BorderSide.none,
          ),
          textStyle: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        child: Text(label),
      ),
    );
  }
}

String _formatCoins(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}
