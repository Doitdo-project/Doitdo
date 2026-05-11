import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/navigation/app_router.dart';
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

  // 탭 index (DoitdoBottomNav.defaultItems 순서 기준)
  static const int _calendarIndex = 0;
  static const int _homeIndex = 1;

  void _onTap(WidgetRef ref, int index) {
    final prevIndex = navigationShell.currentIndex;

    // 캘린더: 이미 보고 있을 때 재탭하면 오늘 날짜로 이동
    if (index == _calendarIndex && index == prevIndex) {
      ref.read(calendarTodayTriggerProvider.notifier).update((v) => v + 1);
    }

    // goBranch 는 GoRouter 내부에서 Navigator 잠금을 유발할 수 있어
    // 다음 프레임으로 미룬다. initialLocation: true 가 서브 라우트를
    // 자동 정리하므로 별도 removeAllSilently() 호출은 불필요하다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigationShell.goBranch(index, initialLocation: true);

      // 홈(다마고치): 어느 탭에서 오든 항상 상단으로 즉시 이동 + 스트릭 갱신 트리거
      if (index == _homeIndex) {
        final controller = ref.read(homeScrollControllerProvider);
        if (controller != null && controller.hasClients) {
          controller.jumpTo(0);
        }
        ref.read(tamagochiEnterTriggerProvider.notifier).update((v) => v + 1);
      }
    });
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