import 'package:flutter/material.dart';

import 'package:doitdo/core/theme/app_colors.dart';
import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/models/todo.dart';

class SlidableTodoItemCard extends StatefulWidget {
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
  State<SlidableTodoItemCard> createState() => _SlidableTodoItemCardState();
}

class _SlidableTodoItemCardState extends State<SlidableTodoItemCard> {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // ✅ 다른 날짜 클릭 불가 문제 해결: onSnooze가 없을 때도 onTap 이벤트를 감싸줍니다.
    if (widget.onSnooze == null) {
      return GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: _buildCard(colors),
      );
    }

    return Stack(
      children: [
        // 1. 배경 레이어 (오른쪽에 고정된 미루기 버튼)
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
                // ✅ 화살표 제거하고 텍스트만 깔끔하게 중앙 정렬
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

        // 2. 전경 레이어 (흰색 Todo 카드)
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
            child: _buildCard(colors),
          ),
        ),
      ],
    );
  }

  // 흰색 카드 UI 구성
  Widget _buildCard(DoitdoColors colors) {
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
                    decoration:
                    widget.todo.isDone ? TextDecoration.lineThrough : null,
                    decorationColor: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                _CategoryBadge(category: widget.todo.category),
              ],
            ),
          ),
          // 드래그 핸들(삼단 햄버거) 제거 — 모바일 ReorderableListView 기본
          // long-press 제스처로 재정렬. 첫 진입 시 안내 툴팁으로 discoverability 보완.
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
  const _CategoryBadge({required this.category});

  final TodoCategory category;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _resolveColors(category.colorKey);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        category.name,
        style: AppTextStyles.labelSmall.copyWith(color: fg),
      ),
    );
  }

  // ✅ 카테고리 색상 실종 문제 해결: 원래 색상값으로 모두 복구
  (Color, Color) _resolveColors(CategoryColorKey key) {
    switch (key) {
      case CategoryColorKey.health:
        return (AppColors.categoryHealth, Colors.white);
      case CategoryColorKey.study:
        return (AppColors.category1, AppColors.calendarDateText);
      case CategoryColorKey.exercise:
        return (AppColors.category2, AppColors.calendarDateText);
      case CategoryColorKey.work:
        return (AppColors.category3, AppColors.calendarDateText);
      case CategoryColorKey.hobby:
        return (AppColors.category5, AppColors.calendarDateText);
      case CategoryColorKey.etc:
        return (AppColors.chipUnselectedBg, AppColors.chipUnselectedText);
    }
  }
}