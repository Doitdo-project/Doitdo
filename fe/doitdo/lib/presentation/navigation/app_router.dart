import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:doitdo/presentation/pages/setting/account/account_page.dart';
import 'package:doitdo/presentation/pages/auth/find_password_page.dart';
import 'package:doitdo/presentation/pages/setting/category/category_page.dart';
import 'package:doitdo/presentation/pages/setting/notification/notification_settings_page.dart';
import 'package:doitdo/presentation/pages/auth/login_page.dart';
import 'package:doitdo/presentation/pages/auth/register_page.dart';
import 'package:doitdo/presentation/pages/auth/reset_password_page.dart';
import 'package:doitdo/presentation/pages/auth/welcome_page.dart';
import 'package:doitdo/presentation/pages/collection/collection_page.dart';
import 'package:doitdo/presentation/pages/setting/setting_page.dart';
import 'package:doitdo/presentation/pages/splash/splash_page.dart';
import 'package:doitdo/presentation/pages/tamagochi/tamagochi_page.dart';
import 'package:doitdo/presentation/pages/todo/todo_page.dart';
import 'package:doitdo/presentation/widgets/shell/doitdo_shell.dart';

/// 앱 라우트 경로 상수.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String findPassword = '/find-password';
  static const String resetPassword = '/reset-password';
  static const String todo = '/todo';
  static const String tamagochi = '/tamagochi';
  static const String tamagochiCollection = '/tamagochi/collection';
  static const String setting = '/setting';
  static const String account = '/setting/account';
  static const String category = '/setting/category';
  static const String notification = '/setting/notification';
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

    // 인증 플로우 (탭 셸 바깥)
    GoRoute(
      path: AppRoutes.welcome,
      builder: (context, state) => const WelcomePage(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: AppRoutes.findPassword,
      builder: (context, state) => const FindPasswordPage(),
    ),
    GoRoute(
      path: AppRoutes.resetPassword,
      builder: (context, state) => const ResetPasswordPage(),
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
              routes: [
                // 상대 경로 'collection' → 절대 경로 '/tamagochi/collection'.
                // parentNavigatorKey 로 rootNavigator 에 push 되도록 해서
                // 전체화면(= bottom nav 숨김)으로 열린다. 뒤로가기는 다마고치 홈으로.
                // 향후 shop 라우트도 동일한 패턴으로 추가.
                GoRoute(
                  path: 'collection',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => const CollectionPage(),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _settingNavigatorKey,
          routes: [
            GoRoute(
              path: AppRoutes.setting,
              builder: (context, state) => const SettingPage(),
              routes: [
                // '/setting/account' — 설정 탭 스택 내부에 push.
                GoRoute(
                  path: 'account',
                  builder: (context, state) => const AccountPage(),
                ),
                // '/setting/category' — 투두 카테고리 관리.
                GoRoute(
                  path: 'category',
                  builder: (context, state) => const CategoryPage(),
                ),
                // '/setting/notification' — 알림 설정.
                GoRoute(
                  path: 'notification',
                  builder: (context, state) =>
                      const NotificationSettingsPage(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
