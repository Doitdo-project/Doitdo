import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/providers/loading_overlay_provider.dart';

/// 앱 전역에서 공통으로 적용되는 시스템 동작만 담당하는 베이스 Scaffold.
///
/// 포함하는 동작:
/// - 테마 배경색
/// - 빈 영역 탭 시 키보드 자동 닫기
/// - 전역 로딩 오버레이(`loadingOverlayProvider`) 구독
/// - SafeArea 처리 (원치 않을 경우 `useSafeArea: false` 로 끌 수 있음)
///
/// 여백/풀블리드 같은 레이아웃 규칙은 이 위에 얹는
/// `DoitdoPaddingLayout`, `DoitdoFullLayout` 이 담당한다.
class DoitdoScaffold extends ConsumerWidget {
  const DoitdoScaffold({
    super.key,
    required this.body,
    this.topBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.resizeToAvoidBottomInset,
    this.backgroundColor,
    this.useSafeArea = true,
    this.extendBodyBehindAppBar = false,
  });

  final Widget body;
  final PreferredSizeWidget? topBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool? resizeToAvoidBottomInset;
  final Color? backgroundColor;
  final bool useSafeArea;
  final bool extendBodyBehindAppBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final isLoading = ref.watch(loadingOverlayProvider);

    Widget content = body;
    if (useSafeArea) {
      content = SafeArea(
        top: topBar == null,
        bottom: bottomNavigationBar == null,
        child: content,
      );
    }

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: backgroundColor ?? colors.background,
        appBar: topBar,
        extendBodyBehindAppBar: extendBodyBehindAppBar,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
        body: Stack(
          children: [
            content,
            if (isLoading)
              Positioned.fill(
                child: ColoredBox(
                  color: colors.scrim,
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}