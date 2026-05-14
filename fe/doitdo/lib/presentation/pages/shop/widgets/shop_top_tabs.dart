import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:doitdo/core/theme/app_colors.dart';
import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/pages/shop/shop_state.dart';

/// 상점 상단 탭 (가구 / 테마). 카테고리 탭보다 한 단계 위 — 가구 카탈로그와 테마
/// 카드 목록을 같은 페이지 안에서 토글한다. 선택 탭은 brand orange 톤 underline
/// 으로 강조해 카테고리 탭(칩)과 시각적 위계를 분리한다.
class ShopTopTabs extends StatelessWidget {
  const ShopTopTabs({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final ShopTab selected;
  final ValueChanged<ShopTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colors.border, width: 1),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Row(
          children: [
            for (final tab in ShopTab.values)
              _TabItem(
                label: tab.label,
                isSelected: tab == selected,
                onTap: () => onSelect(tab),
              ),
          ],
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fg = isSelected ? AppColors.streakCheck : colors.textSecondary;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(right: 20.w),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppColors.streakCheck : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: fg,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
