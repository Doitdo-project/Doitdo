import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/providers/home_scroll_provider.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_bottom_nav.dart';

/// `StatefulShellRoute.indexedStack` 의 바깥 셸.
///
/// 각 탭 분기(navigationShell)를 body 로 받고,
/// 하단에 공통 `DoitdoBottomNav` 를 얹어 탭 간 이동을 처리한다.
/// 탭별 스택은 `navigationShell` 이 자동으로 보존한다.
class DoitdoShell extends ConsumerWidget {
  const DoitdoShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  // 홈 탭 index (DoitdoBottomNav.defaultItems 순서 기준)
  static const int _homeIndex = 1;

  void _onTap(WidgetRef ref, int index) {
    if (index == navigationShell.currentIndex && index == _homeIndex) {
      final controller = ref.read(homeScrollControllerProvider);
      if (controller != null && controller.hasClients) {
        controller.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
        return;
      }
    }
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: navigationShell,
      bottomNavigationBar: DoitdoBottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => _onTap(ref, index),
      ),
    );
  }
}