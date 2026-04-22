import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/core/theme/app_colors.dart';
import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/pages/setting/category/widgets/category_add_sheet.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_dialog.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_top_bar.dart';
import 'package:doitdo/presentation/widgets/layouts/doitdo_padding_layout.dart';
import 'package:doitdo/presentation/widgets/layouts/doitdo_scaffold.dart';

/// 설정 > 투두 카테고리 설정 화면.
///
/// 내 카테고리 목록 + 각 항목 옆 메뉴(편집/삭제) + 하단 "새 카테고리 만들기" 진입점.
/// 현재는 mock 데이터 — 추후 CategoryRepository / CategoryViewModel 로 교체.
class CategoryPage extends ConsumerStatefulWidget {
  const CategoryPage({super.key});

  @override
  ConsumerState<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends ConsumerState<CategoryPage> {
  // TODO: API 연동 시 Repository/ViewModel 로 교체.
  // 색상은 가이드(§7) 에 따라 `AppColors.category*` 팔레트를 직접 참조.
  final List<_Category> _categories = [
    const _Category(id: '1', name: '공부', color: AppColors.category1),
    const _Category(id: '2', name: '업무', color: AppColors.category2),
    const _Category(id: '3', name: '운동', color: AppColors.category3),
    const _Category(id: '4', name: '집안일', color: AppColors.category5),
  ];

  Future<void> _handleAdd() async {
    final result = await showCategoryAddSheet(context);
    if (result == null) return;
    setState(() {
      _categories.add(_Category(
        // 임시 id — 서버 연동 시 실제 카테고리 id 로 교체.
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: result.name,
        color: result.color,
      ));
    });
  }

  Future<void> _handleEdit(_Category category) async {
    final result = await showCategoryAddSheet(
      context,
      initial: CategoryAddResult(
        name: category.name,
        color: category.color,
      ),
    );
    if (result == null) return;
    setState(() {
      final idx = _categories.indexWhere((c) => c.id == category.id);
      if (idx >= 0) {
        _categories[idx] = _Category(
          id: category.id,
          name: result.name,
          color: result.color,
        );
      }
    });
  }

  Future<void> _handleDelete(_Category category) async {
    final ok = await showDoitdoDialog(
      context: context,
      title: '카테고리를 삭제할까요?',
      message: '"${category.name}" 카테고리가 제거됩니다.',
      confirmLabel: '삭제',
      cancelLabel: '취소',
    );
    if (ok != true) return;
    setState(() {
      _categories.removeWhere((c) => c.id == category.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DoitdoScaffold(
      topBar: const DoitdoTopBar(title: '카테고리 설정'),
      body: DoitdoPaddingLayout(
        top: 16,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const _SectionLabel('내 카테고리'),
            const SizedBox(height: 8),
            _CategoryCard(
              categories: _categories,
              onEdit: _handleEdit,
              onDelete: _handleDelete,
              onAddTap: _handleAdd,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

/// 화면 전용 카테고리 데이터 타입.
/// API 연동 시 `domain/entities/category.dart` 의 엔티티로 치환 예정.
class _Category {
  const _Category({
    required this.id,
    required this.name,
    required this.color,
  });

  final String id;
  final String name;
  final Color color;
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

  final List<_Category> categories;
  final ValueChanged<_Category> onEdit;
  final ValueChanged<_Category> onDelete;
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
      // 카드 내부 상/하 여유 공간 — 첫·마지막 행과 카드 경계 사이 호흡.
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
              _AddCategoryRow(onTap: onAddTap),
            ],
          ),
        ),
      ),
    );
  }
}

/// 삼점 메뉴 항목 식별자.
enum _RowMenuAction { edit, delete }

/// 행 삼점 아이콘 위치를 기준으로 팝업 메뉴를 띄우는 헬퍼.
///
/// [iconContext] 는 탭한 아이콘의 BuildContext — 해당 RenderBox 좌표를
/// 기준으로 팝업이 그 아래에 뜨도록 RelativeRect 를 계산한다.
Future<void> _openRowMenu(
  BuildContext iconContext, {
  required VoidCallback onEdit,
  required VoidCallback onDelete,
}) async {
  final box = iconContext.findRenderObject() as RenderBox;
  final overlay =
      Overlay.of(iconContext).context.findRenderObject() as RenderBox;
  // 아이콘의 실제 경계 박스를 overlay 좌표계로 매핑 → 이 박스를 기준으로 메뉴가 인접해 뜬다.
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
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    items: [
      PopupMenuItem(
        value: _RowMenuAction.edit,
        child: Text(
          '수정',
          style: AppTextStyles.bodyMedium.copyWith(
            color: colors.textPrimary,
          ),
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

  final _Category category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: category.color,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              category.name,
              style: AppTextStyles.bodyLarge.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ),
          // PopupMenuButton 은 내부 IconButton 의 48×48 최소 터치 영역 때문에
          // 행 전체 높이를 강제로 키워서 사용 불가 — showMenu 를 직접 호출해 아이콘 크기만 유지.
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
