import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/core/theme/app_colors.dart';
import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/pages/todo/widgets/todo_category_sheet.dart';
import 'package:doitdo/presentation/pages/todo/widgets/todo_date_sheet.dart';
import 'package:doitdo/presentation/pages/todo/widgets/todo_time_sheet.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_primary_button.dart';

class TodoAddSheet extends ConsumerStatefulWidget {
  const TodoAddSheet({super.key, this.initialDate});
  final DateTime? initialDate;

  @override
  ConsumerState<TodoAddSheet> createState() => _TodoAddSheetState();
}

class _TodoAddSheetState extends ConsumerState<TodoAddSheet> {
  final _titleController = TextEditingController();
  final _memoController = TextEditingController();

  TodoDateResult? _dateResult;
  String _selectedCategory = '공부';
  TimeOfDay _selectedTime = const TimeOfDay(hour: 12, minute: 0);

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDate ?? DateTime.now();
    _dateResult = TodoDateResult(type: TodoDateType.normal, date: initial);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour;
    final min = t.minute.toString().padLeft(2, '0');
    final period = h < 12 ? '오전' : '오후';
    final display = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$period $display:$min';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 드래그 핸들
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: c.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),

            // 마스코트 + 안내
            Row(
              children: [
                const _MascotIcon(),
                const SizedBox(width: 8),
                Text('이날 어떤 일을 계획해볼까?',
                    style: AppTextStyles.bodyMedium.copyWith(color: c.textPrimary)),
              ],
            ),
            const SizedBox(height: 16),

            // 할 일 입력
            TextField(
              controller: _titleController,
              style: AppTextStyles.titleMedium.copyWith(color: c.textPrimary),
              decoration: InputDecoration(
                hintText: '할 일을 입력해주세요.',
                hintStyle: AppTextStyles.titleMedium.copyWith(color: c.textHint),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 8),
            Divider(color: c.divider),
            const SizedBox(height: 4),

            // 기간
            GestureDetector(
              onTap: () async {
                final result = await showModalBottomSheet<TodoDateResult>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => TodoDateSheet(
                    initialDate: _dateResult?.date ?? DateTime.now(),
                  ),
                );
                if (result != null) setState(() => _dateResult = result);
              },
              child: _OptionRow(
                icon: Icons.calendar_today_outlined,
                label: '기간',
                valueText: _dateResult?.displayText ?? '',
                colors: c,
              ),
            ),
            Divider(color: c.divider),

            // 카테고리
            GestureDetector(
              onTap: () async {
                final result = await showModalBottomSheet<String>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) =>
                      TodoCategorySheet(selectedCategory: _selectedCategory),
                );
                if (result != null) setState(() => _selectedCategory = result);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  children: [
                    Icon(Icons.category_outlined, size: 18, color: c.textSecondary),
                    const SizedBox(width: 12),
                    Text('카테고리',
                        style: AppTextStyles.bodyMedium.copyWith(color: c.textSecondary)),
                    const Spacer(),
                    Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(
                          color: AppColors.calendarPoint, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(_selectedCategory,
                        style: AppTextStyles.bodyMedium.copyWith(color: c.textPrimary)),
                    const SizedBox(width: 2),
                    Icon(Icons.chevron_right, size: 16, color: c.textHint),
                  ],
                ),
              ),
            ),
            Divider(color: c.divider),

            // 알림
            GestureDetector(
              onTap: () async {
                final result = await showModalBottomSheet<TimeOfDay>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => TodoTimeSheet(initialTime: _selectedTime),
                );
                if (result != null) setState(() => _selectedTime = result);
              },
              child: _OptionRow(
                icon: Icons.notifications_outlined,
                label: '알림',
                valueText: _formatTime(_selectedTime),
                colors: c,
              ),
            ),
            Divider(color: c.divider),

            // ── 메모 (5줄 기본 높이, 입력에 따라 확장) ──
            const SizedBox(height: 16),
            TextField(
              controller: _memoController,
              minLines: 5,       // 기본 5줄 높이
              maxLines: null,    // 입력에 따라 무제한 확장
              keyboardType: TextInputType.multiline,
              style: AppTextStyles.bodyMedium.copyWith(color: c.textPrimary),
              decoration: InputDecoration(
                hintText: '메모를 입력해 보세요.',
                hintStyle: AppTextStyles.bodyMedium.copyWith(color: c.textHint),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 20),

            // 저장하기
            DoitdoPrimaryButton(
              label: '저장하기',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.icon,
    required this.label,
    required this.valueText,
    required this.colors,
  });
  final IconData icon;
  final String label;
  final String valueText;
  final DoitdoColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.textSecondary),
          const SizedBox(width: 12),
          Text(label,
              style: AppTextStyles.bodyMedium.copyWith(color: colors.textSecondary)),
          const Spacer(),
          Text(valueText,
              style: AppTextStyles.bodyMedium.copyWith(color: colors.textPrimary)),
          const SizedBox(width: 2),
          Icon(Icons.chevron_right, size: 16, color: colors.textHint),
        ],
      ),
    );
  }
}

class _MascotIcon extends StatelessWidget {
  const _MascotIcon();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32, height: 32,
      decoration: const BoxDecoration(
          color: AppColors.calendarPoint, shape: BoxShape.circle),
      child: const Icon(Icons.sentiment_satisfied_alt_rounded,
          color: Colors.white, size: 18),
    );
  }
}