import 'package:flutter/material.dart';

import 'package:doitdo/core/theme/doitdo_colors.dart';

/// 공통 상단 바.
///
/// - 메인 탭에서는 사용하지 않고, 상세/세팅 하위 화면처럼
///   뒤로가기(undo)가 필요한 화면에서 사용.
/// - `leading` 을 주지 않으면 Navigator 에서 pop 가능한 경우 자동으로
///   뒤로가기 버튼을 표시.
/// - 색상/폰트는 `AppBarTheme` + `DoitdoColors` 에 위임.
class DoitdoTopBar extends StatelessWidget implements PreferredSizeWidget {
  const DoitdoTopBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.centerTitle = true,
    this.showBackButton = true,
    this.onBack,
    this.backgroundColor,
  });

  final String? title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool centerTitle;
  final bool showBackButton;
  final VoidCallback? onBack;
  final Color? backgroundColor;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    Widget? resolvedLeading = leading;
    if (resolvedLeading == null && showBackButton && Navigator.canPop(context)) {
      resolvedLeading = IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: onBack ?? () => Navigator.maybePop(context),
        color: colors.textPrimary,
      );
    }

    return AppBar(
      backgroundColor: backgroundColor ?? colors.topBarBg,
      leading: resolvedLeading,
      title: title == null ? null : Text(title!),
      centerTitle: centerTitle,
      actions: actions,
    );
  }
}