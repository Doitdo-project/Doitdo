import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/providers/font_family_provider.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_bottom_sheet.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_sheet_action_button.dart';

/// 설정 페이지의 "폰트" 타일에서 열리는 바텀시트.
///
/// 좌우 화살표 대신 라디오 형식으로 [AppFontFamily] 값들을 나열한다.
/// "확인" 누른 시점의 선택이 반환된다. "이전" 또는 바깥 탭 = null.
Future<AppFontFamily?> showFontFamilySheet({
  required BuildContext context,
  required AppFontFamily current,
}) {
  return showDoitdoBottomSheet<AppFontFamily>(
    context: context,
    child: _FontFamilySheet(initial: current),
  );
}

class _FontFamilySheet extends StatefulWidget {
  const _FontFamilySheet({required this.initial});

  final AppFontFamily initial;

  @override
  State<_FontFamilySheet> createState() => _FontFamilySheetState();
}

class _FontFamilySheetState extends State<_FontFamilySheet> {
  late AppFontFamily _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Text(
              '원하는 폰트를 선택해보세요',
              style: AppTextStyles.bodyMedium.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 미리보기 — 선택한 폰트로 즉시 렌더 (확인 누르기 전 비교 가능)
              _PreviewCard(family: _selected, colors: colors),
              const SizedBox(height: 20),
              // 선택지 목록
              for (final family in AppFontFamily.values)
                _FontOptionTile(
                  family: family,
                  selected: _selected == family,
                  colors: colors,
                  onTap: () => setState(() => _selected = family),
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
                      onPressed: () => Navigator.of(context).pop(_selected),
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

/// 선택한 폰트로 즉시 렌더되는 미리보기 카드.
///
/// 시트 내부에서만 family 를 임시로 덮어쓰기 위해 TextStyle 에 직접 fontFamily 를
/// 넣는다. (ThemeData 까지 거치지 않고 즉시 보여주려는 의도)
class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.family, required this.colors});

  final AppFontFamily family;
  final DoitdoColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '오늘의 할 일',
            style: AppTextStyles.titleSmall.copyWith(
              fontFamily: family.family,
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '아침 운동하기',
            style: AppTextStyles.bodyMedium.copyWith(
              fontFamily: family.family,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '영단어 50개 외우기',
            style: AppTextStyles.bodyMedium.copyWith(
              fontFamily: family.family,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Hello, doitdo! 12345',
            style: AppTextStyles.bodySmall.copyWith(
              fontFamily: family.family,
              color: colors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}

class _FontOptionTile extends StatelessWidget {
  const _FontOptionTile({
    required this.family,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  final AppFontFamily family;
  final bool selected;
  final DoitdoColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                family.label,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontFamily: family.family,
                  color: colors.textPrimary,
                ),
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? colors.primary : colors.textHint,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
