import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/core/theme/app_colors.dart';
import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_primary_button.dart';

import 'package:doitdo/data/models/category_dto.dart';
import 'package:doitdo/presentation/pages/setting/category/category_view_model.dart';
import 'package:doitdo/presentation/pages/setting/category/category_page.dart';

class TodoCategorySheet extends ConsumerStatefulWidget {
  const TodoCategorySheet({
    super.key,
    this.selectedCategory,
    this.embedded = false,
    this.onConfirm,
    this.onBack,
  });
  final String? selectedCategory;

  /// 외부 바텀시트 안에 임베드되어 렌더링될지 여부.
  final bool embedded;

  final ValueChanged<CategoryResp>? onConfirm;
  final VoidCallback? onBack;

  @override
  ConsumerState<TodoCategorySheet> createState() => _TodoCategorySheetState();
}

class _TodoCategorySheetState extends ConsumerState<TodoCategorySheet> {
  String? _selectedName;
  CategoryResp? _selectedObj;

  @override
  void initState() {
    super.initState();
    _selectedName = widget.selectedCategory;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final embedded = widget.embedded;
    final chipWidth = (MediaQuery.of(context).size.width - 40 - 12) / 2;

    final asyncCategories = ref.watch(categoryViewModelProvider);

    // 상단 헤더: 마스코트 말풍선 + '수정' 버튼
    final headerRow = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const _MascotBubble(message: '어떤 카테고리야?'),
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CategoryPage()),
            );
          },
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.only(right: 4.0, top: 8.0, bottom: 8.0),
            child: Text(
              '수정',
              style: AppTextStyles.labelMedium.copyWith(color: colors.textSecondary),
            ),
          ),
        ),
      ],
    );

    Widget buildContent(List<CategoryResp> categories) {
      // 삭제 대비 안전장치: 현재 선택된 카테고리가 없으면 첫 번째 항목으로 폴백
      if (_selectedObj == null && _selectedName != null) {
        try {
          _selectedObj = categories.firstWhere((c) => c.categoryName == _selectedName);
        } catch (_) {
          if (categories.isNotEmpty) {
            _selectedObj = categories.first;
            _selectedName = categories.first.categoryName;
          }
        }
      }

      // ✅ + 추가 버튼 제거 — 카테고리 칩만 표시
      final chipsWrap = Wrap(
        spacing: 12,
        runSpacing: 12,
        children: categories.map((cat) {
          final isSelected = _selectedName == cat.categoryName;
          return GestureDetector(
            onTap: () => setState(() {
              _selectedName = cat.categoryName;
              _selectedObj = cat;
            }),
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
                      color: isSelected ? Colors.white70 : cat.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(cat.categoryName,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isSelected ? Colors.white : colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );

      final buttonRow = Row(
        children: [
          Expanded(
            child: _PrevButton(onTap: embedded ? widget.onBack : null),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DoitdoPrimaryButton(
              label: '확인',
              onPressed: () {
                final result = _selectedObj ?? (categories.isNotEmpty ? categories.first : null);
                if (result == null) return;
                if (embedded) {
                  widget.onConfirm?.call(result);
                } else {
                  Navigator.of(context).pop(result);
                }
              },
            ),
          ),
        ],
      );

      if (embedded) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              headerRow,
              Expanded(child: Center(child: chipsWrap)),
              buttonRow,
            ],
          ),
        );
      }

      // SafeArea(top: false): 시스템 네비바 영역만큼 padding 을 더해 시트 하단이
      // 시스템바와 절대 겹치지 않게 한다. 호출부의 useSafeArea: true 와 짝.
      return SafeArea(
        top: false,
        child: Container(
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
              headerRow,
              const SizedBox(height: 20),
              chipsWrap,
              const SizedBox(height: 24),
              buttonRow,
            ],
          ),
        ),
      );
    }

    return asyncCategories.when(
      loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator(color: AppColors.calendarPoint))),
      error: (e, _) => SizedBox(height: 200, child: Center(child: Text('불러오기 실패\n$e', style: AppTextStyles.bodyMedium))),
      data: (categories) => buildContent(categories),
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