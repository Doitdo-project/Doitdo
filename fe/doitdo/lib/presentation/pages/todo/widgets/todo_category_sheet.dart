import 'package:flutter/material.dart';

import 'package:doitdo/core/theme/app_colors.dart';
import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_primary_button.dart';

class TodoCategorySheet extends StatefulWidget {
  const TodoCategorySheet({
    super.key,
    this.selectedCategory,
    this.embedded = false,
    this.onConfirm,
    this.onBack,
  });
  final String? selectedCategory;

  /// 외부 바텀시트(TodoAddSheet 등) 안에 임베드되어 렌더링될지 여부.
  /// true 면 바깥 surface Container · 드래그 핸들을 생략하고, 결과는 [onConfirm]/[onBack]
  /// 콜백으로 돌려준다.
  final bool embedded;
  final ValueChanged<String>? onConfirm;
  final VoidCallback? onBack;

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
    final embedded = widget.embedded;
    final chipWidth = (MediaQuery.of(context).size.width - 40 - 12) / 2;

    final mascot = const _MascotBubble(message: '어떤 카테고리야?');

    final chipsWrap = Wrap(
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
    );

    final buttonRow = Row(
      children: [
        Expanded(
          child: _PrevButton(
            onTap: embedded ? widget.onBack : null,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DoitdoPrimaryButton(
            label: '확인',
            onPressed: () {
              if (embedded) {
                widget.onConfirm?.call(_selected);
              } else {
                Navigator.of(context).pop(_selected);
              }
            },
          ),
        ),
      ],
    );

    // ── 임베드 모드 ──
    // 레이아웃: 말풍선(상단 고정) → 칩 그리드(Expanded · 세로 중앙) → 버튼(하단 고정)
    // 부모(TodoAddSheet) 가 위쪽 20dp 여백과 bounded height 를 제공한다.
    if (embedded) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 상단 고정 ──
            mascot,

            // ── 유연 본문 ──
            // 칩이 5~6개라 작은 폰에서도 한 화면에 들어오므로 Center 로 세로 중앙.
            // 칩이 늘어나면 Wrap 이 자연스럽게 행을 더 추가한다.
            Expanded(
              child: Center(child: chipsWrap),
            ),

            // ── 하단 고정 ──
            buttonRow,
          ],
        ),
      );
    }

    // 기존 독립 바텀시트 경로
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
          mascot,
          const SizedBox(height: 20),
          chipsWrap,
          const SizedBox(height: 24),
          buttonRow,
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
  const _PrevButton({this.onTap});

  /// null 이면 Navigator.pop, 임베드 모드에서는 부모가 단계 전환을 처리한다.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap ?? () => Navigator.of(context).pop(),
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