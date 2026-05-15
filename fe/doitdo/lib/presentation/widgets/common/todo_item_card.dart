import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:doitdo/core/theme/app_colors.dart';
import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/data/models/category_dto.dart';
import 'package:doitdo/presentation/models/todo.dart';
import 'package:doitdo/presentation/pages/setting/category/category_view_model.dart';

class SlidableTodoItemCard extends ConsumerStatefulWidget {
  const SlidableTodoItemCard({
    super.key,
    required this.todo,
    required this.onToggle,
    this.onTap,
    this.index,
    this.onSnooze,
  });

  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback? onTap;
  final int? index;
  final VoidCallback? onSnooze;

  @override
  ConsumerState<SlidableTodoItemCard> createState() => _SlidableTodoItemCardState();
}

class _SlidableTodoItemCardState extends ConsumerState<SlidableTodoItemCard> {
  static const double _snoozeWidth = 80;

  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final categoryList = ref.watch(categoryViewModelProvider).valueOrNull ?? [];
    final badgeColor = widget.todo.colorHex != null
        ? hexToColor(widget.todo.colorHex!)
        : (() {
            try {
              return categoryList.firstWhere((c) => c.categoryName == widget.todo.category.name).color;
            } catch (_) {
              return AppColors.category1;
            }
          }());

    if (widget.onSnooze == null) {
      return GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: _buildCard(colors, badgeColor),
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            alignment: Alignment.centerRight,
            decoration: BoxDecoration(
              color: colors.calendarRangeHighlight,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: GestureDetector(
              onTap: () {
                setState(() => _isOpen = false);
                widget.onSnooze!();
              },
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: _snoozeWidth.w,
                child: Center(
                  child: Text(
                    '미루기',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.calendarPoint),
                  ),
                ),
              ),
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutQuart,
          transform: Matrix4.translationValues(_isOpen ? -_snoozeWidth.w : 0.0, 0.0, 0.0),
          child: GestureDetector(
            onHorizontalDragUpdate: (details) {
              if (details.primaryDelta! < -5 && !_isOpen) {
                setState(() => _isOpen = true);
              } else if (details.primaryDelta! > 5 && _isOpen) {
                setState(() => _isOpen = false);
              }
            },
            onTap: () {
              if (_isOpen) {
                setState(() => _isOpen = false);
              } else {
                widget.onTap?.call();
              }
            },
            behavior: HitTestBehavior.opaque,
            child: _buildCard(colors, badgeColor),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(DoitdoColors colors, Color badgeColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          _CheckDot(isDone: widget.todo.isDone, onTap: widget.onToggle),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.todo.title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: colors.textPrimary,
                    decoration:
                        widget.todo.isDone ? TextDecoration.lineThrough : null,
                    decorationColor: colors.textSecondary,
                  ),
                ),
                SizedBox(height: 4.h),
                _CategoryBadge(
                  category: widget.todo.category,
                  bgColor: badgeColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckDot extends StatelessWidget {
  const _CheckDot({required this.isDone, required this.onTap});

  final bool isDone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      // 동그라미 시각 크기는 22x22 유지, 주변 padding 으로 hit 영역만 키움.
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 4.w),
        child: Container(
          width: 22.w,
          height: 22.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone ? colors.primary : Colors.transparent,
            border: Border.all(
              color: isDone ? colors.primary : colors.border,
              width: 2,
            ),
          ),
          child: isDone
              ? Icon(Icons.check, size: 14.sp, color: colors.onPrimary)
              : null,
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.category, required this.bgColor});

  final TodoCategory category;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    // 배경 luminance 로 글자색 자동 (상세 시트와 동일).
    final fg = bgColor.computeLuminance() > 0.4
        ? AppColors.calendarDateText
        : Colors.white;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        category.name,
        style: AppTextStyles.labelSmall.copyWith(color: fg),
      ),
    );
  }
}
