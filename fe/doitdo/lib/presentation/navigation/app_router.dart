import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:doitdo/presentation/pages/setting/setting_page.dart';
import 'package:doitdo/presentation/pages/splash/splash_page.dart';
import 'package:doitdo/presentation/pages/tamagochi/tamagochi_page.dart';
import 'package:doitdo/presentation/pages/todo/todo_page.dart';
import 'package:doitdo/presentation/widgets/shell/doitdo_shell.dart';

/// 앱 라우트 경로 상수.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String todo = '/todo';
  static const String tamagochi = '/tamagochi';
  static const String setting = '/setting';
}

/// 탭별 중첩 네비게이터가 각자의 스택을 보존하도록 NavigatorKey 분리.
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _todoNavigatorKey = GlobalKey<NavigatorState>();
final _tamagochiNavigatorKey = GlobalKey<NavigatorState>();
final _settingNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashPage(),
    ),

    // 메인 탭 셸. 각 브랜치가 고유의 네비게이션 스택을 가진다.
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return DoitdoShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          navigatorKey: _todoNavigatorKey,
          routes: [
            GoRoute(
              path: AppRoutes.todo,
              builder: (context, state) => const TodoPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _tamagochiNavigatorKey,
          routes: [
            GoRoute(
              path: AppRoutes.tamagochi,
              builder: (context, state) => const TamagochiPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _settingNavigatorKey,
          routes: [
            GoRoute(
              path: AppRoutes.setting,
              builder: (context, state) => const SettingPage(),
            ),
          ],
        ),
      ],
    ),
  ],
);