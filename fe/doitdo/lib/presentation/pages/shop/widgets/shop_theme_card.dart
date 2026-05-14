import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:doitdo/core/theme/app_colors.dart';
import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/domain/entities/furniture_theme.dart';

/// 상점 "테마" 탭의 카드 한 장.
///
/// 카드 자체 탭으로 [onTap] (= 테마 미리보기 토글). 활성 시 border 가 brand
/// 톤으로 강조되고 좌하단에 "미리보기" 뱃지. 구매/배치 버튼은 BE 미구현 단계라
/// 현재 카드에는 노출하지 않는다 — 카드 단일 액션 = 미리보기 토글.
class ShopThemeCard extends StatelessWidget {
  const ShopThemeCard({
    super.key,
    required this.theme,
    required this.isPreviewing,
    required this.onTap,
  });

  final FurnitureTheme theme;
  final bool isPreviewing;
  final VoidCallback onTap;

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
