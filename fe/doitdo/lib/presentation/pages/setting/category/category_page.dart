import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/core/utils/error_message_mapper.dart';
import 'package:doitdo/data/models/category_dto.dart';
import 'package:doitdo/presentation/pages/setting/category/category_view_model.dart';
import 'package:doitdo/presentation/pages/setting/category/widgets/category_add_sheet.dart';
import 'package:doitdo/presentation/pages/setting/category/widgets/palette_selector_sheet.dart';
import 'package:doitdo/presentation/providers/active_palette_provider.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_dialog.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_top_bar.dart';
import 'package:doitdo/presentation/widgets/layouts/doitdo_padding_layout.dart';
import 'package:doitdo/presentation/widgets/layouts/doitdo_scaffold.dart';

/// 설정 > 투두 카테고리 설정 화면.
///
/// CategoryViewModel 을 통해 서버와 연동된다.
/// 추가/수정/삭제는 낙관적 업데이트로 state 를 직접 갱신하며,
/// 실패 시 SnackBar 로 에러 메시지를 노출한다.
class CategoryPage extends ConsumerWidget {
  const CategoryPage({super.key});

  void _showError(BuildContext context, Object e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mapErrorMessage(e))),
    );
  }

  Future<void> _handleAdd(BuildContext context, WidgetRef ref) async {
    final result = await showCategoryAddSheet(context);
    if (result == null) return;
    try {
      await ref.read(categoryViewModelProvider.notifier).addCategory(
            name: result.name,
            colorId: result.colorId,
          );
    } catch (e) {
      if (context.mounted) _showError(context, e);
    }
  }

  Future<void> _handleEdit(
    BuildContext context,
    WidgetRef ref,
    CategoryResp category,
  ) async {
    final result = await showCategoryAddSheet(
      context,
      initial: CategoryAddResult(
        name: category.categoryName,
        colorId: category.colorId,
      ),
    );
    if (result == null) return;
    try {
      await ref.read(categoryViewModelProvider.notifier).editCategory(
            categoryId: category.categoryId,
            name: result.name,
            colorId: result.colorId,
          );
    } catch (e) {
      if (context.mounted) _showError(context, e);
    }
  }

  /// 팔레트 시트에서 "확인" 누른 직후 동작.
  /// 모든 카테고리를 새 팔레트의 같은 인덱스 색으로 일괄 PATCH 후 활성 팔레트 갱신.
  ///
  /// 실패 시: 활성 팔레트는 갱신하지 않고 카테고리를 서버에서 재조회한다.
  /// 이렇게 하지 않으면 "활성 팔레트 = 네온" / "카테고리 색 = 이전" 같은
  /// 모순 상태가 남는다 (PATCH 실패로 카테고리는 안 바뀌었는데 활성 팔레트만 바뀐 경우).
  Future<void> _handlePaletteChange(
    BuildContext context,
    WidgetRef ref,
    int newPaletteId,
    PaletteListResp palettes,
  ) async {
    final prevPaletteId = ref.read(activePaletteProvider);
    // 낙관적: 팔레트 이름 즉시 변경
    await ref.read(activePaletteProvider.notifier).set(newPaletteId);
    try {
      await ref.read(categoryViewModelProvider.notifier).applyPaletteToAll(
            newPaletteId: newPaletteId,
            paletteList: palettes,
          );
    } catch (e) {
      // 실패: 팔레트 이름·카테고리 모두 서버 진실 상태로 복구
      if (prevPaletteId != null) {
        await ref.read(activePaletteProvider.notifier).set(prevPaletteId);
      }
      ref.invalidate(categoryViewModelProvider);
      if (context.mounted) _showError(context, e);
    }
  }

  Future<void> _handleDelete(
    BuildContext context,
    WidgetRef ref,
    CategoryResp category,
  ) async {
    final ok = await showDoitdoDialog(
      context: context,
      title: '카테고리를 삭제할까요?',
      message: '"${category.categoryName}" 카테고리가 제거됩니다.',
      confirmLabel: '삭제',
      cancelLabel: '취소',
    );
    if (ok != true) return;
    try {
      await ref
          .read(categoryViewModelProvider.notifier)
          .removeCategory(category.categoryId);
    } catch (e) {
      if (context.mounted) _showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(categoryViewModelProvider);

    return DoitdoScaffold(
      topBar: const DoitdoTopBar(title: '카테고리 설정'),
      body: DoitdoPaddingLayout(
        top: 16,
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  mapErrorMessage(e),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: context.colors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => ref.invalidate(categoryViewModelProvider),
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          ),
          data: (categories) => ListView(
            padding: EdgeInsets.zero,
            children: [
              const _SectionLabel('팔레트 설정'),
              const SizedBox(height: 8),
              _PaletteSelector(
                onChanged: (newPaletteId, palettes) =>
                    _handlePaletteChange(context, ref, newPaletteId, palettes),
              ),
              const SizedBox(height: 24),
              const _SectionLabel('내 카테고리 (최대 6개)'),
              const SizedBox(height: 8),
              _CategoryCard(
                categories: categories,
                onEdit: (c) => _handleEdit(context, ref, c),
                onDelete: (c) => _handleDelete(context, ref, c),
                onAddTap: () => _handleAdd(context, ref),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        style: AppTextStyles.labelMedium.copyWith(
          color: context.colors.textHint,
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.categories,
    required this.onEdit,
    required this.onDelete,
    required this.onAddTap,
  });

  final List<CategoryResp> categories;
  final ValueChanged<CategoryResp> onEdit;
  final ValueChanged<CategoryResp> onDelete;
  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: Column(
            children: [
              for (final c in categories)
                _CategoryRow(
                  category: c,
                  onEdit: () => onEdit(c),
                  onDelete: () => onDelete(c),
                ),
              if (categories.length < 6)
                _AddCategoryRow(onTap: onAddTap),
            ],
          ),
        ),
      ),
    );
  }
}

enum _RowMenuAction { edit, delete }

/// 행 삼점 아이콘 위치를 기준으로 팝업 메뉴를 띄우는 헬퍼.
///
/// [iconContext] 의 RenderBox 좌표로 RelativeRect 를 계산해
/// PopupMenuButton 없이 아이콘 크기만 유지하면서 메뉴를 띄운다.
Future<void> _openRowMenu(
  BuildContext iconContext, {
  required VoidCallback onEdit,
  required VoidCallback onDelete,
}) async {
  final box = iconContext.findRenderObject() as RenderBox;
  final overlay =
      Overlay.of(iconContext).context.findRenderObject() as RenderBox;
  final position = RelativeRect.fromRect(
    Rect.fromPoints(
      box.localToGlobal(Offset.zero, ancestor: overlay),
      box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
    ),
    Offset.zero & overlay.size,
  );

  final colors = iconContext.colors;
  final action = await showMenu<_RowMenuAction>(
    context: iconContext,
    position: position,
    color: colors.surface,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    items: [
      PopupMenuItem(
        value: _RowMenuAction.edit,
        child: Text(
          '수정',
          style: AppTextStyles.bodyMedium.copyWith(color: colors.textPrimary),
        ),
      ),
      PopupMenuItem(
        value: _RowMenuAction.delete,
        child: Text(
          '삭제',
          // 파괴적 액션 — 고정 빨강 톤 (시맨틱 토큰 생기면 교체).
          style: AppTextStyles.bodyMedium.copyWith(
            color: const Color(0xFFE04040),
          ),
        ),
      ),
    ],
  );
  if (action == _RowMenuAction.edit) {
    onEdit();
  } else if (action == _RowMenuAction.delete) {
    onDelete();
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  final CategoryResp category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // colorHex 를 서버에서 직접 받아 Color 로 변환.
    final dotColor = category.color;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              category.categoryName,
              style: AppTextStyles.bodyLarge.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ),
          Builder(
            builder: (iconContext) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _openRowMenu(
                  iconContext,
                  onEdit: onEdit,
                  onDelete: onDelete,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.more_vert,
                    size: 18,
                    color: colors.textHint,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// 카테고리 페이지 상단 팔레트 진입 카드.
///
/// 한 줄짜리 카드 — 현재 활성 팔레트 이름 + chevron right. 탭하면
/// [showPaletteSelectorSheet] 로 좌우 화살표 미리보기 시트가 열린다.
/// 시트에서 "확인" 을 누르면 [onChanged] 콜백으로 새 paletteId 가 전달되어
/// 부모가 모든 카테고리를 일괄 PATCH 한다.
///
/// 첫 진입 시 활성 팔레트 ID 가 null 이면 paletteProvider 데이터를 받자마자
/// 첫 팔레트로 자동 set 한다 (post-frame).
class _PaletteSelector extends ConsumerWidget {
  const _PaletteSelector({required this.onChanged});

  final void Function(int newPaletteId, PaletteListResp palettes) onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final palette = ref.watch(paletteProvider);
    final activeId = ref.watch(activePaletteProvider);

    return palette.when(
      loading: () => const SizedBox(
        height: 64,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
        ),
        child: InkWell(
          // FutureProvider 는 한 번 실패하면 그 에러 상태로 머무르므로
          // 사용자가 직접 invalidate 해 다시 GET 을 트리거하게 한다.
          onTap: () => ref.invalidate(paletteProvider),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 20,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '팔레트를 불러오지 못했어요',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colors.textHint,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.refresh, size: 16, color: colors.textHint),
              ],
            ),
          ),
        ),
      ),
      data: (paletteList) {
        final palettes = paletteList.items;
        if (palettes.isEmpty) return const SizedBox.shrink();

        var currentIndex = palettes.indexWhere((p) => p.paletteId == activeId);
        if (currentIndex < 0) currentIndex = 0;

        // activePaletteProvider 가 null 이면(= 로그아웃 후 첫 진입 등)
        // 서버 카테고리의 colorId 로 실제 팔레트를 역추론해 설정한다.
        // 단순히 첫 팔레트(기본)로 고정하면 서버 색상과 선택된 팔레트 이름이
        // 어긋나는 현상이 발생하기 때문.
        if (activeId == null) {
          final cats = ref.read(categoryViewModelProvider).valueOrNull ?? [];
          if (cats.isNotEmpty) {
            final firstColorId = cats.first.colorId;
            int base = 1;
            for (int i = 0; i < palettes.length; i++) {
              final p = palettes[i];
              if (firstColorId >= base && firstColorId < base + p.colors.length) {
                currentIndex = i;
                break;
              }
              base += p.colors.length;
            }
          }
          final detectedId = palettes[currentIndex].paletteId;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            ref.read(activePaletteProvider.notifier).set(detectedId);
          });
        }

        final current = palettes[currentIndex];

        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                final picked = await showPaletteSelectorSheet(
                  context,
                  currentPaletteId: current.paletteId,
                );
                if (picked == null || picked == current.paletteId) return;
                onChanged(picked, paletteList);
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        current.paletteName,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: colors.textHint,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AddCategoryRow extends StatelessWidget {
  const _AddCategoryRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        child: Row(
          children: [
            Icon(Icons.add, size: 16, color: colors.textHint),
            const SizedBox(width: 12),
            Text(
              '새 카테고리 만들기',
              style: AppTextStyles.bodyLarge.copyWith(
                color: colors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
