import 'package:flutter/material.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';

/// "< 라벨" 형태로 chevron + 텍스트가 좌측에 붙어 있는 헤더.
///
/// 표준 [AppBar] 의 `leading + 가운데 title` 패턴과 다른 디자인이다.
/// 인증 플로우(login / register / find-password / reset-password) 의
/// 상단 바로 공용 사용한다.
class InlineBackBar extends StatelessWidget {
  const InlineBackBar({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      height: kToolbarHeight,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: TextButton.icon(
            onPressed: Navigator.canPop(context)
                ? () => Navigator.maybePop(context)
                : null,
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
