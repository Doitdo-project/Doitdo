import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:doitdo/presentation/pages/setting/account/account_page.dart';
import 'package:doitdo/presentation/pages/setting/bug_report/bug_report_page.dart';
import 'package:doitdo/presentation/pages/auth/find_password_page.dart';
import 'package:doitdo/presentation/pages/setting/category/category_page.dart';
import 'package:doitdo/presentation/pages/notification/notification_page.dart';
import 'package:doitdo/presentation/pages/setting/notification/notification_settings_page.dart';
import 'package:doitdo/presentation/pages/auth/login_page.dart';
import 'package:doitdo/presentation/pages/auth/register_page.dart';
import 'package:doitdo/presentation/pages/auth/reset_password_page.dart';
import 'package:doitdo/presentation/pages/auth/welcome_page.dart';
import 'package:doitdo/presentation/pages/collection/collection_page.dart';
import 'package:doitdo/presentation/pages/onboarding/onboarding_agreements_page.dart';
import 'package:doitdo/presentation/pages/onboarding/onboarding_birth_date_page.dart';
import 'package:doitdo/presentation/pages/setting/setting_page.dart';
import 'package:doitdo/presentation/pages/shop/shop_page.dart';
import 'package:doitdo/presentation/pages/splash/splash_page.dart';
import 'package:doitdo/presentation/pages/tamagochi/character_hatch_page.dart';
import 'package:doitdo/presentation/pages/tamagochi/character_naming_page.dart';
import 'package:doitdo/presentation/pages/tamagochi/tamagochi_page.dart';
import 'package:doitdo/presentation/pages/todo/todo_page.dart';
import 'package:doitdo/presentation/pages/tutorial/tutorial_page.dart';
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
  // 온보딩 (첫 로그인 시 1단계 → 2단계 → 메인 탭).
  static const String onboardingBirthDate = '/onboarding/birth-date';
  static const String onboardingAgreements = '/onboarding/agreements';
  static const String todo = '/todo';
  static const String tamagochi = '/tamagochi';
  static const String tamagochiCollection = '/tamagochi/collection';
  static const String tamagochiShop = '/tamagochi/shop';
  static const String tamagochiHatch = '/tamagochi/hatch';
  static const String tamagochiNaming = '/tamagochi/naming';
  static const String setting = '/setting';
  static const String account = '/setting/account';
  static const String category = '/setting/category';
  static const String notification = '/setting/notification';
  static const String bugReport = '/setting/bug-report';
  static const String notifications = '/todo/notifications';
  static const String tutorial = '/tutorial';
}

/// 탭별 중첩 네비게이터가 각자의 스택을 보존하도록 NavigatorKey 분리.
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _todoNavigatorKey = GlobalKey<NavigatorState>();
final _tamagochiNavigatorKey = GlobalKey<NavigatorState>();
final _settingNavigatorKey = GlobalKey<NavigatorState>();

/// 각 브랜치의 모든 라우트(페이지·바텀시트·다이얼로그)를 추적한다.
/// 탭 전환 시 [removeAllSilently]로 루트(첫 번째) 라우트만 남기고
/// 나머지를 애니메이션 없이 즉시 제거한다.
class BranchPopupTracker extends NavigatorObserver {
  final _routes = <Route>[];

  /// 루트 라우트(index 0)를 제외한 모든 라우트를 역순으로 즉시 제거.
  /// Navigator.removeRoute 는 역방향 애니메이션을 재생하지 않는다.
  void removeAllSilently() {
    if (_routes.length <= 1) return;
    for (final route in _routes.skip(1).toList().reversed) {
      navigator?.removeRoute(route);
    }
    _routes.removeRange(1, _routes.length);
  }

  @override
  void didPush(Route route, Route? previousRoute) => _routes.add(route);

  @override
  void didPop(Route route, Route? previousRoute) => _routes.remove(route);

  @override
  void didRemove(Route route, Route? previousRoute) => _routes.remove(route);

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    if (oldRoute == null) return;
    final i = _routes.indexOf(oldRoute);
    if (i >= 0 && newRoute != null) _routes[i] = newRoute;
  }
}

/// 셸에서 참조할 수 있도록 module-level 로 노출.
final todoBranchTracker     = BranchPopupTracker();
final tamagochiBranchTracker = BranchPopupTracker();
final settingBranchTracker  = BranchPopupTracker();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoutes.splash,
  // 외부 진입(홈스크린 위젯 / 푸시 알림 / 카카오·구글 OAuth 콜백 등) 이 보낸 URL 은
  // path 가 우리 라우트 목록에 없어 GoException 으로 떨어질 수 있다.
  // 위젯 진입(`doitdo://widget/...`) 만큼은 안전하게 splash 로 흡수해서 부팅 흐름 재사용.
  redirect: (context, state) {
    final raw = state.uri.toString();
    final path = state.uri.path;
    if (raw.startsWith('doitdo://widget') || path.startsWith('/widget')) {
      return '${AppRoutes.splash}?from=widget';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => SplashPage(
        fromWidget: state.uri.queryParameters['from'] == 'widget',
      ),
    ),

    // 홈스크린 위젯에서 진입(`doitdo://widget/open`) 시 받는 라우트.
    // 자체 페이지를 가지지 않고 splash 로 redirect — 거기서 토큰 유무에 따라
    // 메인/로그인 화면으로 분기되는 기존 부팅 흐름을 그대로 재사용한다.
    GoRoute(
      path: '/widget/open',
      redirect: (context, state) => '${AppRoutes.splash}?from=widget',
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

    // 튜토리얼 (첫 진입 시 메인 탭 진입 전 1회 표시).
    // next 쿼리 파라미터로 완료 후 이동할 탭을 전달한다.
    GoRoute(
      path: AppRoutes.tutorial,
      builder: (context, state) => TutorialPage(
        next: state.uri.queryParameters['next'] ?? AppRoutes.tamagochi,
      ),
    ),

    // 온보딩 (첫 로그인 — 인증 직후 진입, 메인 탭 이전).
    // back stack 에 인증 화면을 남기지 않기 위해 호출측은 context.go(...) 사용.
    GoRoute(
      path: AppRoutes.onboardingBirthDate,
      builder: (context, state) => const OnboardingBirthDatePage(),
    ),
    GoRoute(
      path: AppRoutes.onboardingAgreements,
      builder: (context, state) => const OnboardingAgreementsPage(),
    ),

    // 메인 탭 셸. 각 브랜치가 고유의 네비게이션 스택을 가진다.
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return DoitdoShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          navigatorKey: _todoNavigatorKey,
          observers: [todoBranchTracker],
          routes: [
            GoRoute(
              path: AppRoutes.todo,
              builder: (context, state) => const TodoPage(),
              routes: [
                // '/todo/notifications' — 전체 화면(bottom nav 숨김).
                // parentNavigatorKey: _rootNavigatorKey 로 root 스택에 push.
                GoRoute(
                  path: 'notifications',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => const NotificationPage(),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _tamagochiNavigatorKey,
          observers: [tamagochiBranchTracker],
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
                // '/tamagochi/shop' — 방 꾸미기 상점 (전체 화면).
                GoRoute(
                  path: 'shop',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => const ShopPage(),
                ),
                // '/tamagochi/hatch' — 알을 10회 두드려 부화시키는 전체 화면.
                GoRoute(
                  path: 'hatch',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => const CharacterHatchPage(),
                ),
                // '/tamagochi/naming' — 알 부화 직후 이름 짓기 전체 화면.
                GoRoute(
                  path: 'naming',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => const CharacterNamingPage(),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _settingNavigatorKey,
          observers: [settingBranchTracker],
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
                // '/setting/bug-report' — 버그 신고.
                GoRoute(
                  path: 'bug-report',
                  builder: (context, state) => const BugReportPage(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
