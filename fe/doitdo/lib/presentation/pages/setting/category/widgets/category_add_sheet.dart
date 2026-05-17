import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/data/models/category_dto.dart';
import 'package:doitdo/presentation/pages/setting/category/category_view_model.dart';
import 'package:doitdo/presentation/providers/active_palette_provider.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_bottom_sheet.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_sheet_action_button.dart';

/// 카테고리 추가/수정 바텀시트.
///
/// [initial] 이 null 이면 추가 모드, 값이 있으면 수정 모드 (이름·색상 초기값 채움).
/// 확인 시 [CategoryAddResult] 반환. 이전/바깥 탭/뒤로가기 시 null.
Future<CategoryAddResult?> showCategoryAddSheet(
  BuildContext context, {
  CategoryAddResult? initial,
}) {
  return showDoitdoBottomSheet<CategoryAddResult>(
    context: context,
    child: _CategoryAddSheet(initial: initial),
  );
}

/// 시트가 반환하는 결과 타입.
class CategoryAddResult {
  const CategoryAddResult({
    required this.name,
    required this.colorId,
  });

  final String name;

  /// 서버 팔레트의 colorId (1-based).
  final int colorId;
}

class _CategoryAddSheet extends ConsumerStatefulWidget {
  const _CategoryAddSheet({this.initial});

  final CategoryAddResult? initial;

  @override
  ConsumerState<_CategoryAddSheet> createState() => _CategoryAddSheetState();
}

class _CategoryAddSheetState extends ConsumerState<_CategoryAddSheet> {
  late final TextEditingController _nameCtrl =
      TextEditingController(text: widget.initial?.name ?? '');
  late int? _selectedColorId = widget.initial?.colorId;

  bool get _isEdit => widget.initial != null;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  bool get _canConfirm =>
      _nameCtrl.text.trim().isNotEmpty && _selectedColorId != null;

  void _submit() {
    if (!_canConfirm) return;
    Navigator.of(context).pop(
      CategoryAddResult(
        name: _nameCtrl.text.trim(),
        colorId: _selectedColorId!,
      ),
    );
  }

  /// 다른 카테고리들이 이미 쓰는 colorId 집합 — 시트의 색 그리드에서 비활성화 표시.
  /// 수정 모드면 자기 자신(initial.colorId) 은 빼서 본인 색은 그대로 다시 선택 가능.
  Set<int> _disabledColorIds(List<CategoryResp> categories) {
    final selfId = widget.initial?.colorId;
    return categories
        .where((c) => c.colorId != selfId)
        .map((c) => c.colorId)
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final categories = ref.watch(categoryViewModelProvider).valueOrNull ?? const [];
    final disabledIds = _disabledColorIds(categories);

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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            children: [
              _NameField(
                controller: _nameCtrl,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              _ColorPickerBox(
                selectedColorId: _selectedColorId,
                disabledColorIds: disabledIds,
                onSelect: (id) => setState(() => _selectedColorId = id),
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
                      onPressed: _canConfirm ? _submit : null,
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

/// 카테고리 추가/수정 시트의 색상 피커 박스.
///
/// **활성 팔레트(`activePaletteProvider`) 의 색만** 그리드로 보여준다.
/// 시트 안에서 팔레트를 바꾸는 좌우 화살표는 의도적으로 두지 않는다 — 팔레트
/// 변경은 카테고리 페이지 상단의 `_PaletteSelector` 가 단일 진입점이고, 거기서
/// 바꾸면 모든 카테고리가 일괄로 같이 바뀐다.
///
/// [disabledColorIds] 에 포함된 colorId 는 다른 카테고리가 이미 쓰는 색 — 시각적으로
/// 사용 중 표시(체크 아이콘) 를 띄우고 탭을 막아 색상 중복을 방지한다.
class _ColorPickerBox extends ConsumerWidget {
  const _ColorPickerBox({
    required this.selectedColorId,
    required this.disabledColorIds,
    required this.onSelect,
  });

  final int? selectedColorId;
  final Set<int> disabledColorIds;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final palette = ref.watch(paletteProvider);
    final activeId = ref.watch(activePaletteProvider);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
      child: palette.when(
        loading: () => const SizedBox(
          height: 80,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => SizedBox(
          height: 80,
          child: Center(
            child: Text(
              '색상을 불러오지 못했어요',
              style: AppTextStyles.bodySmall.copyWith(color: colors.textHint),
            ),
          ),
        ),
        data: (paletteList) {
          final palettes = paletteList.items;
          if (palettes.isEmpty) return const SizedBox(height: 80);

          // 활성 팔레트 인덱스 — 못 찾으면 첫 팔레트 (방어).
          var currentIndex =
              palettes.indexWhere((p) => p.paletteId == activeId);
          if (currentIndex < 0) currentIndex = 0;
          final currentPalette = palettes[currentIndex];

          // BE 가 직접 내려준 colorId 를 그대로 사용 — 추측 계산 불필요.
          // (이전엔 displayOrder 누적으로 baseId 를 추정했으나, BE MR
          //  `be/fix/palette-resp-color-id` 로 PaletteColorResp.colorId 가 응답에
          //  포함되어 그 가정이 필요 없어짐.)
          return _buildColorGrid(currentPalette.colors, colors);
        },
      ),
    );
  }

  Widget _buildColorGrid(
    List<PaletteColorResp> paletteColors,
    DoitdoColors colors,
  ) {
    const int cols = 4;
    final rows = (paletteColors.length / cols).ceil();

    return Column(
      children: List.generate(rows, (rowIdx) {
        final start = rowIdx * cols;
        final end = (start + cols).clamp(0, paletteColors.length);
        final rowItems = paletteColors.sublist(start, end);

        return Padding(
          padding:
              rowIdx > 0 ? const EdgeInsets.only(top: 14) : EdgeInsets.zero,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ...rowItems.map((pc) {
                final colorId = pc.colorId;
                final color = hexToColor(pc.color);
                final isUsed = disabledColorIds.contains(colorId);
                return _ColorCircle(
                  color: color,
                  colorId: colorId,
                  isSelected: selectedColorId == colorId,
                  isUsed: isUsed,
                  onTap: isUsed ? null : () => onSelect(colorId),
                );
              }),
              // 마지막 줄 빈 칸 채우기 — 4개 미만일 때 정렬 유지.
              ...List.generate(
                cols - rowItems.length,
                (_) => const SizedBox(width: 36, height: 36),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _ColorCircle extends StatelessWidget {
  const _ColorCircle({
    required this.color,
    required this.colorId,
    required this.isSelected,
    required this.isUsed,
    required this.onTap,
  });

  final Color color;
  final int colorId;
  final bool isSelected;

  /// 다른 카테고리가 이미 쓰는 색 — 체크 아이콘 + 반투명 + 탭 비활성.
  final bool isUsed;

  /// null 이면 탭 비활성 (사용 중인 색).
  final VoidCallback? onTap;

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
        child: isUsed
            ? const Center(
                child: Icon(
                  Icons.check,
                  size: 20,
                  color: Colors.white,
                  // 밝은 색 위에서도 체크가 묻히지 않게 그림자로 외곽선 효과.
                  shadows: [
                    Shadow(
                      offset: Offset(0, 0),
                      blurRadius: 3,
                      color: Color(0x88000000),
                    ),
                  ],
                ),
              )
            : null,
      ),
    );
  }
}
