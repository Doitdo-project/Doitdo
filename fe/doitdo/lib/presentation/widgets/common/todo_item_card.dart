import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // ✅ 추가

import 'package:doitdo/core/theme/app_colors.dart';
import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/models/todo.dart';
import 'package:doitdo/presentation/pages/setting/category/category_view_model.dart'; // ✅ 추가

// ✅ StatefulWidget → ConsumerStatefulWidget 으로 변경 (Riverpod 접근 필요)
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
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // ✅ 서버 카테고리 목록에서 실제 색상 조회
    final categoryList = ref.watch(categoryViewModelProvider).valueOrNull ?? [];
    Color getBadgeBgColor(String categoryName) {
      try {
        return categoryList.firstWhere((c) => c.categoryName == categoryName).color;
      } catch (_) {
        return AppColors.calendarPoint; // 매칭 없으면 기본 오렌지
      }
    }

    if (widget.onSnooze == null) {
      return GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: _buildCard(colors, getBadgeBgColor),
      );
    }

    return Stack(
      children: [
        // 배경 레이어 (미루기 버튼)
        Positioned.fill(
          child: Container(
            alignment: Alignment.centerRight,
            decoration: BoxDecoration(
              color: AppColors.homeCalendarSelectedBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: GestureDetector(
              onTap: () {
                setState(() => _isOpen = false);
                widget.onSnooze!();
              },
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 80,
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

        // 전경 레이어 (Todo 카드)
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutQuart,
          transform: Matrix4.translationValues(_isOpen ? -80.0 : 0.0, 0.0, 0.0),
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
            child: _buildCard(colors, getBadgeBgColor),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(DoitdoColors colors, Color Function(String) getBadgeBgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          _CheckDot(isDone: widget.todo.isDone, onTap: widget.onToggle),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.todo.title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: colors.textPrimary,
                    decoration: widget.todo.isDone ? TextDecoration.lineThrough : null,
                    decorationColor: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                // ✅ 서버에서 가져온 실제 색상을 뱃지에 전달
                _CategoryBadge(
                  category: widget.todo.category,
                  bgColor: getBadgeBgColor(widget.todo.category.name),
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
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDone ? colors.primary : Colors.transparent,
          border: Border.all(
            color: isDone ? colors.primary : colors.border,
            width: 2,
          ),
        ),
        child: isDone
            ? Icon(Icons.check, size: 14, color: colors.onPrimary)
            : null,
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({
    required this.category,
    required this.bgColor, // ✅ 하드코딩 제거 — 외부에서 실제 색상 주입
  });

  final TodoCategory category;
  final Color bgColor; // ✅ 서버 카테고리 색상

  @override
  Widget build(BuildContext context) {
    // ✅ 배경색 밝기에 따라 텍스트 색상 자동 결정 (가독성 보장)
    final luminance = bgColor.computeLuminance();
    final fgColor = luminance > 0.4 ? AppColors.calendarDateText : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        category.name,
        style: AppTextStyles.labelSmall.copyWith(color: fgColor),
      ),
    );
  }
}