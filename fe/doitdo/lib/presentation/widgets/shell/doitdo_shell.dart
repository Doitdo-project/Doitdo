import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_bottom_nav.dart';

/// `StatefulShellRoute.indexedStack` 의 바깥 셸.
///
/// 각 탭 분기(navigationShell)를 body 로 받고,
/// 하단에 공통 `DoitdoBottomNav` 를 얹어 탭 간 이동을 처리한다.
/// 탭별 스택은 `navigationShell` 이 자동으로 보존한다.
class DoitdoShell extends StatelessWidget {
  const DoitdoShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    // 현재 탭을 한 번 더 누르면 해당 탭의 스택을 루트로 되돌린다.
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: navigationShell,
      bottomNavigationBar: DoitdoBottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: _onTap,
      ),
    );
  }
}