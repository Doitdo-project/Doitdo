import 'package:flutter/material.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/models/todo.dart';
import 'package:doitdo/presentation/widgets/common/todo_item_card.dart';

/// 섹션 타이틀 + 우측 액션(선택) + `TodoItemCard` 리스트.
///
/// 예) "오늘의 할 일 | 추가하기" 형태의 헤더와 그 아래 카드들.
/// 여백은 부모에서 준다 (이 위젯은 좌우 패딩을 갖지 않음).
class TodoSection extends StatelessWidget {
  const TodoSection({
    super.key,
    required this.title,
    required this.todos,
    required this.onToggle,
    this.actionLabel,
    this.onActionTap,
  });

  final String title;
  final List<Todo> todos;
  final ValueChanged<String> onToggle;

  /// 헤더 우측에 표시할 텍스트 액션. 예: "추가하기"
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: AppTextStyles.titleSmall.copyWith(
                color: colors.textPrimary,
              ),
            ),
            if (actionLabel != null)
              GestureDetector(
                onTap: onActionTap,
                behavior: HitTestBehavior.opaque,
                child: Text(
                  actionLabel!,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < todos.length; i++) ...[
          TodoItemCard(
            todo: todos[i],
            onToggle: () => onToggle(todos[i].id),
          ),
          if (i != todos.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}