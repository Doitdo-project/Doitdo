import 'package:flutter/material.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';

/// 공통 바텀시트 컨테이너.
///
/// ### 시스템 네비바 + 키보드 동시 보정
/// - 호출부에서 `showModalBottomSheet(useSafeArea: true)` 가 modal 의
///   `MediaQuery.padding.bottom` 을 **보존**해 준다 (Flutter 기본은 제거함).
/// - 보존된 padding 은 자동 적용되지 않으므로 시트 내부에서 `SafeArea(top: false)`
///   로 명시적으로 소비해야 시스템 네비바(뒤로가기/홈/멀티태스킹) 영역을 피한다.
/// - 키보드는 `viewInsets.bottom` 을 직접 Padding 으로 더한다. 키보드가 올라온
///   동안엔 padding.bottom 이 0 으로 떨어져 SafeArea 와 합산해도 중복되지 않는다.
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
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: keyboardInset),
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
      ),
    );
  }
}

/// 바텀시트를 편하게 띄우는 헬퍼.
///
/// `useSafeArea: true` 로 modal 의 `MediaQuery.padding.bottom` 이 보존되도록 하고,
/// 시트 위젯 안의 [SafeArea] 가 그 값을 소비해 시스템 네비바 영역을 피한다.
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
