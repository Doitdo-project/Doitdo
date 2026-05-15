import 'package:flutter/material.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';

/// "< 라벨" 형태로 chevron + 텍스트가 좌측에 붙어 있는 헤더.
///
/// 표준 [AppBar] 의 `leading + 가운데 title` 패턴과 다른 디자인이다.
/// 인증 플로우(login / register / find-password / reset-password) 의
/// 상단 바로 공용 사용한다.
///
/// 기본 동작은 [Navigator.maybePop] — 위에 쌓인 라우트가 있으면 pop.
/// 위에 라우트가 없을 때(예: `context.go` 로 진입해 스택이 비어버린 경우) 는
/// 보통 비활성화되지만, [fallback] 을 주면 그 콜백이 대신 실행된다.
/// 인증 플로우의 진입 화면들이 항상 어딘가로 빠져나갈 수 있게 하는 데 사용.
class InlineBackBar extends StatelessWidget {
  const InlineBackBar({
    super.key,
    required this.label,
    this.fallback,
  });

  final String label;

  /// [Navigator.canPop] 이 false 일 때 대신 호출할 콜백.
  /// null 이면 기존 동작(버튼 비활성).
  final VoidCallback? fallback;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final canPop = Navigator.canPop(context);
    final VoidCallback? onPressed = canPop
        ? () => Navigator.maybePop(context)
        : fallback;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: kToolbarHeight),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: TextButton.icon(
            onPressed: onPressed,
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: colors.textPrimary,
            ),
            label: Text(
              label,
              style: AppTextStyles.titleSmall.copyWith(
                color: colors.textPrimary,
              ),
            ),
            style: TextButton.styleFrom(
              foregroundColor: colors.textPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      ),
    );
  }
}
