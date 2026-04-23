import 'package:flutter/material.dart';

import 'package:doitdo/core/theme/app_colors.dart';
import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_primary_button.dart';

class TodoCategorySheet extends StatefulWidget {
  const TodoCategorySheet({super.key, this.selectedCategory});
  final String? selectedCategory;

  @override
  State<TodoCategorySheet> createState() => _TodoCategorySheetState();
}

class _TodoCategorySheetState extends State<TodoCategorySheet> {
  late String _selected;

  static const List<Map<String, dynamic>> _categories = [
    {'name': '공부', 'color': AppColors.category1},
    {'name': '운동', 'color': AppColors.category2},
    {'name': '업무', 'color': AppColors.category3},
    {'name': '건강', 'color': AppColors.category4},
    {'name': '취미', 'color': AppColors.category5},
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedCategory ?? '공부';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final chipWidth = (MediaQuery.of(context).size.width - 40 - 12) / 2;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const _MascotBubble(message: '어떤 카테고리야?'),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ..._categories.map((cat) {
                final name = cat['name'] as String;
                final dotColor = cat['color'] as Color;
                final isSelected = _selected == name;
                return GestureDetector(
                  onTap: () => setState(() => _selected = name),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: chipWidth,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.calendarPoint : colors.surfaceAlt,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white70 : dotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(name,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: isSelected ? Colors.white : colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: chipWidth,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: colors.surfaceAlt,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, size: 16, color: colors.textSecondary),
                      const SizedBox(width: 4),
                      Text('추가', style: AppTextStyles.bodyMedium.copyWith(color: colors.textSecondary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(child: _PrevButton()),
              const SizedBox(width: 8),
              Expanded(
                child: DoitdoPrimaryButton(
                  label: '확인',
                  onPressed: () => Navigator.of(context).pop(_selected),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MascotBubble extends StatelessWidget {
  const _MascotBubble({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset('assets/images/Dooit.png', width: 32, height: 32),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.bubbleBg,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(12),
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
          child: Text(message,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.calendarDateText),
          ),
        ),
      ],
    );
  }
}

class _PrevButton extends StatelessWidget {
  const _PrevButton();
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => Navigator.of(context).pop(),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.loginBtnOff,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: Text('이전', style: AppTextStyles.bodyLarge.copyWith(color: Colors.white)),
    );
  }
}