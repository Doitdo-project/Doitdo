import 'package:flutter/material.dart';

import 'package:doitdo/core/theme/app_colors.dart';
import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_bottom_sheet.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_sheet_action_button.dart';

/// 카테고리 추가/수정 바텀시트.
///
/// [initial] 이 null 이면 추가 모드 ("카테고리 추가"), 값이 있으면 수정 모드 ("카테고리 수정")
/// 로 동작하며 이름/색상 필드에 초기값이 채워진다.
///
/// [확인] 시 입력한 (name, color) 반환. 이전 / 바깥 탭 / 뒤로가기 시 null.
Future<CategoryAddResult?> showCategoryAddSheet(
  BuildContext context, {
  CategoryAddResult? initial,
}) {
  return showDoitdoBottomSheet<CategoryAddResult>(
    context: context,
    child: _CategoryAddSheet(initial: initial),
  );
}

/// 시트가 반환하는 결과 타입 (Dart record 대신 명시 클래스 — public API 안정성 위해).
class CategoryAddResult {
  const CategoryAddResult({required this.name, required this.color});

  final String name;
  final Color color;
}

class _CategoryAddSheet extends StatefulWidget {
  const _CategoryAddSheet({this.initial});

  final CategoryAddResult? initial;

  @override
  State<_CategoryAddSheet> createState() => _CategoryAddSheetState();
}

class _CategoryAddSheetState extends State<_CategoryAddSheet> {
  late final TextEditingController _nameCtrl =
      TextEditingController(text: widget.initial?.name ?? '');
  late Color? _selectedColor = widget.initial?.color;

  bool get _isEdit => widget.initial != null;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  bool get _canConfirm =>
      _nameCtrl.text.trim().isNotEmpty && _selectedColor != null;

  void _submit() {
    if (!_canConfirm) return;
    Navigator.of(context).pop(
      CategoryAddResult(
        name: _nameCtrl.text.trim(),
        color: _selectedColor!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 28, bottom: 16),
          child: Text(
            _isEdit ? '카테고리 수정' : '카테고리 추가',
            style: AppTextStyles.titleSmall.copyWith(
              color: colors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // 입력 필드 / 색상 박스 / 버튼 영역 공통 좌우 패딩 — 다른 설정 시트들과 동일한 30 총폭.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            children: [
              _NameField(
                controller: _nameCtrl,
                // 입력 값이 바뀌면 _canConfirm 가 바뀌므로 부모 rebuild.
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              _ColorPickerBox(
                selected: _selectedColor,
                onSelect: (c) => setState(() => _selectedColor = c),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: DoitdoSheetActionButton(
                      label: '이전',
                      isPrimary: false,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DoitdoSheetActionButton(
                      label: '확인',
                      // 시각적으로는 항상 오렌지 유지 — 미입력/미선택 시 _submit 이 내부에서 no-op.
                      onPressed: _submit,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 이름 입력 필드 — 흰 배경 + 회색 외곽선.
class _NameField extends StatelessWidget {
  const _NameField({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: AppTextStyles.bodyLarge.copyWith(color: colors.textPrimary),
        decoration: InputDecoration(
          hintText: '카테고리를 입력하세요.',
          hintStyle: AppTextStyles.bodyLarge.copyWith(color: colors.textHint),
          border: InputBorder.none,
          isCollapsed: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }
}

/// 기본 색상 팔레트 박스 — 타이틀 + 좌/우 화살표 + 8개 원형 선택지.
///
/// 화살표는 추후 커스텀 팔레트 페이지네이션 확장용. 현재는 시각적 요소만.
class _ColorPickerBox extends StatelessWidget {
  const _ColorPickerBox({required this.selected, required this.onSelect});

  final Color? selected;
  final ValueChanged<Color> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.chevron_left, size: 20, color: colors.textPrimary),
              Expanded(
                child: Center(
                  child: Text(
                    '기본 색상',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ),
              Icon(Icons.chevron_right, size: 20, color: colors.textPrimary),
            ],
          ),
          const SizedBox(height: 20),
          for (var rowIndex = 0; rowIndex < 2; rowIndex++) ...[
            if (rowIndex > 0) const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final c in AppColors.categories.sublist(
                    rowIndex * 4, rowIndex * 4 + 4))
                  _ColorCircle(
                    color: c,
                    isSelected: selected == c,
                    onTap: () => onSelect(c),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ColorCircle extends StatelessWidget {
  const _ColorCircle({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: isSelected
              ? Border.all(color: colors.primary, width: 3)
              : null,
        ),
      ),
    );
  }
}
