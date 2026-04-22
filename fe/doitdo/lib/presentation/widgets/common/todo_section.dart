import 'package:flutter/material.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/models/todo.dart';
import 'package:doitdo/presentation/widgets/common/todo_item_card.dart';

class TodoSection extends StatelessWidget {
  const TodoSection({
    super.key,
    required this.title,
    required this.todos,
    required this.onToggle,
    this.onReorder,
    this.actionLabel,
    this.onActionTap,
    this.onTodoTap,
    this.onSnooze, // ✅ 추가
  });

  final String title;
  final List<Todo> todos;
  final ValueChanged<String> onToggle;
  final ReorderCallback? onReorder;

  final String? actionLabel;
  final VoidCallback? onActionTap;
  final void Function(Todo todo)? onTodoTap;
  final void Function(String id)? onSnooze; // ✅ 추가

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── 섹션 헤더 ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: AppTextStyles.titleSmall.copyWith(color: colors.textPrimary),
            ),
            if (actionLabel != null)
              GestureDetector(
                onTap: onActionTap,
                behavior: HitTestBehavior.opaque,
                child: Text(
                  actionLabel!,
                  style: AppTextStyles.labelMedium.copyWith(color: colors.textSecondary),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // ── 목록 ──
        if (todos.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                '할 일을 추가해보세요!',
                style: AppTextStyles.bodySmall.copyWith(color: colors.textHint),
              ),
            ),
          )
        else if (onReorder != null)
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: todos.length,
            onReorder: onReorder!,
            proxyDecorator: (Widget child, int index, Animation<double> animation) {
              return Material(
                color: Colors.transparent,
                elevation: 0,
                child: child,
              );
            },
            itemBuilder: (context, index) {
              final todo = todos[index];
              // ✅ 오늘 날짜의 미완료 TODO인지 확인
              final canSnooze = onSnooze != null && !todo.isDone;

              return Padding(
                key: ValueKey(todo.id),
                padding: EdgeInsets.only(bottom: index == todos.length - 1 ? 0 : 12),
                child: SlidableTodoItemCard( // ✅ SlidableTodoItemCard 로 변경
                  todo: todo,
                  index: index,
                  onToggle: () => onToggle(todo.id),
                  onTap: onTodoTap != null ? () => onTodoTap!(todo) : null,
                  onSnooze: canSnooze ? () => onSnooze!(todo.id) : null,
                ),
              );
            },
          )
        else
          for (var i = 0; i < todos.length; i++) ...[
            Builder(
                builder: (context) {
                  final todo = todos[i];
                  final canSnooze = onSnooze != null && !todo.isDone;

                  return SlidableTodoItemCard( // ✅ SlidableTodoItemCard 로 변경
                    todo: todo,
                    onToggle: () => onToggle(todo.id),
                    onTap: onTodoTap != null ? () => onTodoTap!(todo) : null,
                    onSnooze: canSnooze ? () => onSnooze!(todo.id) : null,
                  );
                }
            ),
            if (i != todos.length - 1) const SizedBox(height: 12),
          ],
      ],
    );
  }
}