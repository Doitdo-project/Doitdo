import 'package:flutter/material.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';

/// 공통 바텀시트 컨테이너.
///
/// 키보드는 `viewInsets.bottom` 을 Padding 으로 더해 시트를 밀어 올린다.
/// 시스템 네비바(safe area) 는 Container 내부 padding 에 흡수 — 외부에 SafeArea 를
/// 쓰면 root navigator context 에서 padding.bottom 이 전체 시스템 inset 이 되어
/// Container 아래에 투명 공백이 생기기 때문이다.
class DoitdoBottomSheet extends StatelessWidget {
  const DoitdoBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.showDragHandle = true,
  });

  final Widget child;
  final String? title;
  final bool showDragHandle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final mq = MediaQuery.of(context);
    final keyboardInset = mq.viewInsets.bottom;
    final bottomSafeArea = mq.padding.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomSafeArea),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showDragHandle)
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            if (title != null) ...[
              Text(
                title!,
                style: AppTextStyles.titleSmall.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
            ],
            Flexible(child: child),
          ],
        ),
      ),
    );
  }
}

/// 바텀시트를 편하게 띄우는 헬퍼.
Future<T?> showDoitdoBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  String? title,
  bool isScrollControlled = true,
  bool isDismissible = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DoitdoBottomSheet(title: title, child: child),
  );
}
