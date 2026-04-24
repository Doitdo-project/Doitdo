import 'package:flutter/material.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';

/// 앱 전체에서 재사용하는 기본 버튼. Radius 12 로 고정.
///
/// [onPressed] 가 null 이면 disabled 상태로 표시.
class DoitdoPrimaryButton extends StatelessWidget {
  const DoitdoPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.expand = true,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onPressed;

  /// true 면 부모 너비에 맞춰 늘어난다.
  final bool expand;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final button = SizedBox(
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          disabledBackgroundColor: colors.border,
          disabledForegroundColor: colors.textHint,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTextStyles.bodyMedium,
        ),
        child: Text(label),
      ),
    );

    if (!expand) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}