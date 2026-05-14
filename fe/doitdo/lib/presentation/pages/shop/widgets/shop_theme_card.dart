import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:doitdo/core/theme/app_colors.dart';
import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/domain/entities/furniture_theme.dart';
import 'package:doitdo/presentation/pages/shop/widgets/coin_icon.dart';

/// 상점 "테마" 탭의 카드 한 장.
///
/// 카드 자체 탭 = [onTap] (테마 미리보기 토글). 하단 버튼은 가구 카드와 일관된
/// 단일 액션:
/// - 미보유 → "구매"  ([onTapPurchase] = 주문서 다이얼로그 오픈)
/// - 풀세트 보유 → "배치" ([onTapPlace] = 테마 일괄 배치 API 호출)
///
/// 잔액 부족 분기는 카드에 표시하지 않고 다이얼로그가 처리한다 — 가구 카드의
/// "구매" 도 잔액과 무관하게 항상 활성이고 다이얼로그에서만 비활성된다.
class ShopThemeCard extends StatelessWidget {
  const ShopThemeCard({
    super.key,
    required this.theme,
    required this.isPreviewing,
    required this.onTap,
    required this.onTapPurchase,
    required this.onTapPlace,
  });

  final FurnitureTheme theme;
  final bool isPreviewing;
  final VoidCallback onTap;
  final VoidCallback onTapPurchase;
  final VoidCallback onTapPlace;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final borderColor =
        isPreviewing ? AppColors.streakCheck : colors.border;
    final borderWidth = isPreviewing ? 1.5 : 1.0;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        padding: EdgeInsets.all(10.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _Thumbnail(theme: theme, isPreviewing: isPreviewing)),
            SizedBox(height: 8.h),
            Text(
              theme.themeName,
              style: AppTextStyles.bodyMedium.copyWith(color: colors.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 2.h),
            Text(
              '${theme.furnitureCount}종 가구',
              style: AppTextStyles.bodySmall.copyWith(color: colors.textSecondary),
            ),
            SizedBox(height: 6.h),
            _StatusOrPriceLine(theme: theme),
            SizedBox(height: 8.h),
            _ActionButton(
              theme: theme,
              onTapPurchase: onTapPurchase,
              onTapPlace: onTapPlace,
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.theme, required this.isPreviewing});

  final FurnitureTheme theme;
  final bool isPreviewing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: Container(
              color: colors.streakCardBg,
              alignment: Alignment.center,
              child: theme.thumbnailUrl.isEmpty
                  ? Icon(
                      Icons.collections_bookmark_outlined,
                      size: 32.sp,
                      color: colors.textHint,
                    )
                  : Image.network(
                      theme.thumbnailUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.broken_image_outlined,
                        size: 28.sp,
                        color: colors.textHint,
                      ),
                    ),
            ),
          ),
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

/// 가구 카드 [_StatusOrPriceLine] 와 같은 자리·톤. 풀세트 보유면 "보유 중", 그
/// 외엔 결제가(`purchasePrice`) 표시. 보유 가구가 일부 있어 정가보다 결제가가
/// 낮아진 경우 정가를 취소선으로 같이 보여줘 "이게 할인된 금액이구나" 가
/// 한눈에 들어오도록 한다.
class _StatusOrPriceLine extends StatelessWidget {
  const _StatusOrPriceLine({required this.theme});

  final FurnitureTheme theme;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (theme.alreadyOwned) {
      return Text(
        '보유 중',
        style: AppTextStyles.bodySmall.copyWith(color: colors.textSecondary),
      );
    }
    final discounted = theme.totalPrice > theme.purchasePrice;
    return Row(
      children: [
        CoinIcon(size: 16.sp),
        SizedBox(width: 4.w),
        if (discounted) ...[
          Text(
            _formatCoins(theme.totalPrice),
            style: AppTextStyles.labelSmall.copyWith(
              color: colors.textHint,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          SizedBox(width: 4.w),
        ],
        Flexible(
          child: Text(
            _formatCoins(theme.purchasePrice),
            style: AppTextStyles.labelMedium.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// 가구 카드 [_ActionButton] 과 같은 자리·톤. 미보유 → primary "구매", 풀세트
/// 보유 → secondary "배치" (가구 카드의 owned 케이스 톤과 동일).
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.theme,
    required this.onTapPurchase,
    required this.onTapPlace,
  });

  final FurnitureTheme theme;
  final VoidCallback onTapPurchase;
  final VoidCallback onTapPlace;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg, onTap) = theme.alreadyOwned
        ? ('배치', AppColors.streakBg, AppColors.streakCheck, onTapPlace)
        : ('구매', AppColors.streakCheck, Colors.white, onTapPurchase);

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
