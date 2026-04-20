import 'package:flutter/material.dart';

import 'package:doitdo/core/theme/app_colors.dart';
import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/models/todo.dart';

/// 할 일 한 건을 카드 형태로 표시하는 공통 위젯.
///
/// 체크박스(원형 토글) + 제목 + 카테고리 뱃지 구성.
/// 완료 상태일 때 제목에 취소선이 들어간다.
class TodoItemCard extends StatelessWidget {
  const TodoItemCard({
    super.key,
    required this.todo,
    required this.onToggle,
  });

  final Todo todo;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          _CheckDot(isDone: todo.isDone, onTap: onToggle),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  todo.title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: colors.textPrimary,
                    decoration:
                        todo.isDone ? TextDecoration.lineThrough : null,
                    decorationColor: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                _CategoryBadge(category: todo.category),
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

/// 카테고리 뱃지. 현재는 Health 만 커스텀 매핑이고 나머지는 중립 컬러.
/// 카테고리 컬러 시스템이 확정되면 `_resolveColors` 를 채운다.
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

  (Color, Color) _resolveColors(CategoryColorKey key) {
    switch (key) {
      case CategoryColorKey.health:
        return (AppColors.categoryHealth, Colors.white);
      case CategoryColorKey.study:
      case CategoryColorKey.work:
      case CategoryColorKey.hobby:
      case CategoryColorKey.etc:
        // TODO: 카테고리별 컬러 매핑 확정 후 채움
        return (AppColors.chipUnselectedBg, AppColors.chipUnselectedText);
    }
  }
}