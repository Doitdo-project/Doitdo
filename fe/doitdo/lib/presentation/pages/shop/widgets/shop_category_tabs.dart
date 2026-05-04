import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:doitdo/core/theme/app_colors.dart';
import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/pages/shop/shop_state.dart';

/// 가로 스크롤 카테고리 탭. 선택된 칩만 brand orange 톤으로 강조한다.
class ShopCategoryTabs extends StatelessWidget {
  const ShopCategoryTabs({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final ShopCategory selected;
  final ValueChanged<ShopCategory> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        itemCount: ShopCategory.values.length,
        separatorBuilder: (_, _) => SizedBox(width: 8.w),
        itemBuilder: (context, i) {
          final cat = ShopCategory.values[i];
          return _CategoryChip(
            category: cat,
            isSelected: cat == selected,
            onTap: () => onSelect(cat),
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  final ShopCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bg = isSelected
        ? AppColors.streakBg
        : colors.surface;
    final fg = isSelected
        ? AppColors.streakCheck
        : colors.textSecondary;
    final border = isSelected
        ? AppColors.streakCheck
        : colors.border;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: border, width: isSelected ? 1.2 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(category.icon, size: 14.sp, color: fg),
            SizedBox(width: 6.w),
            Text(
              category.label,
              style: AppTextStyles.labelLarge.copyWith(
                color: fg,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
