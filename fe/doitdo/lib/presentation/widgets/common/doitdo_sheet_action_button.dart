import 'package:flutter/material.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';

/// 바텀시트 하단의 주/보조 액션 버튼.
///
/// `isPrimary = true` 는 확정 액션(확인/저장 등), false 는 취소/이전.
/// 시트 안에서 보통 Row + Expanded 로 좌(이전) / 우(확인) 쌍으로 배치한다.
///
/// [onPressed] 가 null 이면 disabled 로 렌더 — 폼 유효성 검사 전에 확인 버튼을 막을 때 사용.
class DoitdoSheetActionButton extends StatelessWidget {
  const DoitdoSheetActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isPrimary = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = onPressed != null;
    final bg = isPrimary ? colors.primary : colors.surfaceAlt;
    final fg = isPrimary ? colors.onPrimary : colors.textSecondary;
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: colors.border,
          disabledForegroundColor: colors.textHint,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyLarge.copyWith(
            color: enabled ? fg : colors.textHint,
          ),
        ),
      ),
    );
  }
}
