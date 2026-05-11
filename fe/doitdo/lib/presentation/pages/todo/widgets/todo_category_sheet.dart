import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/core/theme/app_colors.dart';
import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_primary_button.dart';
import 'package:doitdo/presentation/widgets/common/character_mascot_image.dart';

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
    // 칩 가로폭은 LayoutBuilder 가 알려주는 실제 본문 너비 기준으로 계산.
    // (embedded / standalone 의 외곽 padding 이 달라 화면 너비 기반은 부정확.)
    const chipSpacing = 12.0;

    final asyncCategories = ref.watch(categoryViewModelProvider);

    const headerRow = _MascotBubble(message: '어떤 카테고리야?');

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

      // LayoutBuilder 로 실제 가용 너비 기준 3열 정사각형 카드 분배.
      // 카드 안: 가운데 색상 원 + 그 아래 카테고리명 (세로 배치).
      // 카테고리 6개 미만이면 마지막 칸에 + 칩을 추가해 CategoryPage 로 진입.
      final chipsWrap = LayoutBuilder(
        builder: (context, constraints) {
          // 한 줄 3개 → 사이 간격 2개 분량 빼고 3등분.
          final chipWidth =
              (constraints.maxWidth - chipSpacing * 2) / 3;
          return Wrap(
            spacing: chipSpacing,
            runSpacing: chipSpacing,
            children: [
              ...categories.map((cat) {
                final isSelected = _selectedName == cat.categoryName;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedName = cat.categoryName;
                    _selectedObj = cat;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: chipWidth,
                    height: chipWidth, // 정사각형
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.calendarPoint
                          : colors.surfaceAlt,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: cat.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding:
                          const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            cat.categoryName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : colors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              if (categories.length < 6)
                GestureDetector(
                  onTap: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    final nav = Navigator.of(context, rootNavigator: true);
                    nav.pop(); // TodoAddSheet 모달 제거 → 스크림 없애기
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      nav.push(
                        MaterialPageRoute(
                          builder: (_) => const CategoryPage(),
                        ),
                      );
                    });
                  },
                  child: Container(
                    width: chipWidth,
                    height: chipWidth,
                    decoration: BoxDecoration(
                      color: colors.surfaceAlt,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.add,
                      size: 28,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
            ],
          );
        },
      );

      final buttonRow = Row(
        children: [
          Expanded(
            child: _PrevButton(onTap: embedded ? widget.onBack : null),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DoitdoPrimaryButton(
              height: 48,
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
        // 부모(todo_add_sheet) 가 StackFit.expand 로 잔여 높이를 통째로 넘김.
        // mainAxisSize.max + Expanded 로 마스코트(상단)/버튼(하단) anchor.
        // 본문은 Center 로 가운데 배치 — 알림 시트 휠과 동일한 시각 패턴.
        // 카테고리가 많아져 잔여 높이를 넘치면 LayoutBuilder + ConstrainedBox 로 스크롤 폴백.
        // 좌우/상단 padding 24/14 — todo_add_sheet 메인폼과 동일하게 맞춰
        // 마스코트 위치를 일치시킨다.
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              headerRow,
              const SizedBox(height: 16),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Center(child: chipsWrap),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              buttonRow,
            ],
          ),
        );
      }

      // SafeArea(top: false, minimum: 8): 시스템 네비바와 시각 간격 보장 +
      // useSafeArea 가 꺼져 있어도 최소 8px 버퍼.
      return SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 8),
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

/// todo_add_sheet 와 동일 스펙(36×36 + 꼬리형 BorderRadius).
class _MascotBubble extends StatelessWidget {
  const _MascotBubble({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const CharacterMascotImage(size: 36),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const BoxDecoration(
            color: AppColors.bubbleBg,
            borderRadius: BorderRadius.only(
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
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text('이전', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
    );
  }
}