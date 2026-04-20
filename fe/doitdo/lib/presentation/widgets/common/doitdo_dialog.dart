import 'package:flutter/material.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_primary_button.dart';

/// 공통 다이얼로그. Radius 24 로 고정.
///
/// 일반적인 확인/취소 다이얼로그는 `showDoitdoDialog` 헬퍼를 사용하고,
/// 복잡한 콘텐츠가 필요한 경우 이 위젯을 `showDialog` 의 builder
/// 안에서 직접 구성해 쓴다.
class DoitdoDialog extends StatelessWidget {
  const DoitdoDialog({
    super.key,
    this.title,
    this.message,
    this.content,
    this.confirmLabel = '확인',
    this.cancelLabel,
    this.onConfirm,
    this.onCancel,
  });

  final String? title;
  final String? message;

  /// 커스텀 본문. 주어지면 [message] 대신 표시된다.
  final Widget? content;

  final String confirmLabel;
  final String? cancelLabel;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Dialog(
      backgroundColor: colors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null)
              Text(
                title!,
                style: AppTextStyles.titleSmall.copyWith(
                  color: colors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            if (title != null) const SizedBox(height: 12),
            if (content != null)
              content!
            else if (message != null)
              Text(
                message!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: colors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 20),
            Row(
              children: [
                if (cancelLabel != null) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onCancel ??
                          () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.textPrimary,
                        side: BorderSide(color: colors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: AppTextStyles.bodyLarge,
                      ),
                      child: Text(cancelLabel!),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: DoitdoPrimaryButton(
                    label: confirmLabel,
                    onPressed: onConfirm ??
                        () => Navigator.of(context).pop(true),
                    height: 48,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 확인/취소 다이얼로그를 편하게 띄우는 헬퍼.
///
/// 확인 시 `true`, 취소/외부 탭 시 `false` 또는 `null` 을 반환.
Future<bool?> showDoitdoDialog({
  required BuildContext context,
  String? title,
  String? message,
  Widget? content,
  String confirmLabel = '확인',
  String? cancelLabel,
  bool barrierDismissible = true,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (_) => DoitdoDialog(
      title: title,
      message: message,
      content: content,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
    ),
  );
}