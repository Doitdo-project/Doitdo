import 'package:flutter/material.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/providers/default_screen_provider.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_bottom_sheet.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_sheet_action_button.dart';

/// 설정 > 기본 화면 선택 바텀시트.
///
/// 앱을 다시 켰을 때 처음으로 보여줄 탭(홈 / 캘린더) 을 선택한다.
///
/// 반환: [확인] 선택 시 [DefaultScreen], [이전] / 바깥 탭 / 뒤로가기 시 null.
Future<DefaultScreen?> showDefaultScreenSheet({
  required BuildContext context,
  required DefaultScreen current,
}) {
  return showDoitdoBottomSheet<DefaultScreen>(
    context: context,
    child: _DefaultScreenSheet(initialSelection: current),
  );
}

class _DefaultScreenSheet extends StatefulWidget {
  const _DefaultScreenSheet({required this.initialSelection});

  final DefaultScreen initialSelection;

  @override
  State<_DefaultScreenSheet> createState() => _DefaultScreenSheetState();
}

class _DefaultScreenSheetState extends State<_DefaultScreenSheet> {
  late DefaultScreen _selected = widget.initialSelection;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 타이틀 위아래 여백 — drag handle / 옵션 카드와 숨 쉴 공간 확보.
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Text(
            '앱을 시작할 때 기본 홈 화면으로\n표시할 화면을 선택해 주세요',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: colors.textPrimary,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // 카드 / 버튼 영역에 추가 좌우 여백 — 시트 기본 패딩(20) 위에 10 더해 총 30.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ScreenOption(
                title: '홈',
                description: '오늘의 할 일과 캐릭터를 한눈에 확인',
                isSelected: _selected == DefaultScreen.home,
                onTap: () => setState(() => _selected = DefaultScreen.home),
              ),
              const SizedBox(height: 12),
              _ScreenOption(
                title: '캘린더',
                description: '날짜별 할 일과 기록을 확인',
                isSelected: _selected == DefaultScreen.calendar,
                onTap: () =>
                    setState(() => _selected = DefaultScreen.calendar),
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

/// 선택지 카드 — 좌측 체크 인디케이터 + 제목 + 설명.
///
/// 선택 상태 강조: primary 색의 8% 알파를 카드 배경에 깔아 라이트에선 크림톤,
/// 다크에선 다크 surface 위 살짝 오렌지 톤이 자동으로 적응되도록 한다.
/// 보더는 시맨틱 토큰(`colors.border`) 사용 — 다크 모드에서도 가독성 확보.
class _ScreenOption extends StatelessWidget {
  const _ScreenOption({
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
        decoration: BoxDecoration(
          // 선택 시: primary 알파 8% — 라이트/다크 모두 자연스러운 톤.
          color: isSelected
              ? colors.primary.withOpacity(0.08)
              : colors.surface,
          borderRadius: BorderRadius.circular(12),
          // 선택/비선택 동일한 2px 로 유지 — 두께 전환으로 인한 레이아웃 점프 방지.
          border: Border.all(
            color: isSelected ? colors.primary : colors.border,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            _CheckIndicator(isSelected: isSelected),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckIndicator extends StatelessWidget {
  const _CheckIndicator({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? colors.primary : colors.surface,
        border: isSelected ? null : Border.all(color: colors.border),
      ),
      child: isSelected
          ? const Icon(Icons.check, size: 18, color: Colors.white)
          : null,
    );
  }
}
