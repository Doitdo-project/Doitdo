import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/data/models/category_dto.dart';
import 'package:doitdo/presentation/pages/setting/category/category_view_model.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_bottom_sheet.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_sheet_action_button.dart';

/// 카테고리 페이지 상단의 팔레트 카드 탭 시 열리는 시트.
///
/// 좌우 화살표로 팔레트 미리보기 → "확인" 누른 시점에만 [paletteId] 가 반환된다.
/// 부모는 받은 paletteId 로 모든 카테고리를 일괄 PATCH 한다.
/// "이전" 또는 바깥 탭 = null (변경 안 함).
Future<int?> showPaletteSelectorSheet(
  BuildContext context, {
  required int currentPaletteId,
}) {
  return showDoitdoBottomSheet<int>(
    context: context,
    child: _PaletteSelectorSheet(currentPaletteId: currentPaletteId),
  );
}

class _PaletteSelectorSheet extends ConsumerStatefulWidget {
  const _PaletteSelectorSheet({required this.currentPaletteId});

  final int currentPaletteId;

  @override
  ConsumerState<_PaletteSelectorSheet> createState() =>
      _PaletteSelectorSheetState();
}

class _PaletteSelectorSheetState
    extends ConsumerState<_PaletteSelectorSheet> {
  /// 현재 미리보고 있는 팔레트 인덱스. null 이면 currentPaletteId 의 인덱스.
  int? _previewIndex;

  int _resolveIndex(List<PaletteResp> palettes) {
    final fromState = _previewIndex;
    if (fromState != null) return fromState.clamp(0, palettes.length - 1);
    final byId = palettes.indexWhere((p) => p.paletteId == widget.currentPaletteId);
    return byId < 0 ? 0 : byId;
  }

  void _confirm(List<PaletteResp> palettes) {
    final idx = _resolveIndex(palettes);
    Navigator.of(context).pop(palettes[idx].paletteId);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final palette = ref.watch(paletteProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 24),
        palette.when(
          loading: () => const SizedBox(
            height: 240,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => SizedBox(
            height: 240,
            child: Center(
              child: Text(
                '팔레트를 불러오지 못했어요',
                style:
                    AppTextStyles.bodySmall.copyWith(color: colors.textHint),
              ),
            ),
          ),
          data: (paletteList) {
            final palettes = paletteList.items;
            if (palettes.isEmpty) return const SizedBox.shrink();

            final idx = _resolveIndex(palettes);
            final current = palettes[idx];
            final hasPrev = idx > 0;
            final hasNext = idx < palettes.length - 1;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      _ChevronButton(
                        icon: Icons.chevron_left,
                        enabled: hasPrev,
                        onTap: () =>
                            setState(() => _previewIndex = idx - 1),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            current.paletteName,
                            style: AppTextStyles.titleMedium.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      _ChevronButton(
                        icon: Icons.chevron_right,
                        enabled: hasNext,
                        onTap: () =>
                            setState(() => _previewIndex = idx + 1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _PalettePreviewGrid(colors: current.colors),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
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
                  onPressed: () {
                    final palettes =
                        ref.read(paletteProvider).valueOrNull?.items;
                    if (palettes == null || palettes.isEmpty) {
                      Navigator.of(context).pop();
                      return;
                    }
                    _confirm(palettes);
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _ChevronButton extends StatelessWidget {
  const _ChevronButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          size: 24,
          color: enabled ? colors.textPrimary : colors.textHint,
        ),
      ),
    );
  }
}

/// 시트 안의 색 미리보기 — 탭 불가, 단순 표시용.
class _PalettePreviewGrid extends StatelessWidget {
  const _PalettePreviewGrid({required this.colors});

  final List<PaletteColorResp> colors;

  @override
  Widget build(BuildContext context) {
    const int cols = 4;
    final rows = (colors.length / cols).ceil();
    return Column(
      children: List.generate(rows, (rowIdx) {
        final start = rowIdx * cols;
        final end = (start + cols).clamp(0, colors.length);
        final rowItems = colors.sublist(start, end);
        return Padding(
          padding:
              rowIdx > 0 ? const EdgeInsets.only(top: 14) : EdgeInsets.zero,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ...rowItems.map(
                (pc) => Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hexToColor(pc.color),
                  ),
                ),
              ),
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
