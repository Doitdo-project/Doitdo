import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:doitdo/core/errors/exceptions.dart';
import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/core/utils/app_env.dart';
import 'package:doitdo/presentation/navigation/app_router.dart';
import 'package:doitdo/presentation/navigation/post_auth_destination.dart';
import 'package:doitdo/presentation/providers/app_data_providers.dart';
import 'package:doitdo/presentation/providers/current_user_provider.dart';
import 'package:doitdo/presentation/providers/default_screen_provider.dart';

/// 앱 부팅 직후 잠시 노출되는 스플래시 + **세션 복원 분기 지점**.
///
/// secure storage 에 저장된 토큰 유무로 초기 라우팅을 결정한다:
/// - 토큰 없음 → Welcome 화면
/// - 토큰 있음 → `GET /api/users/me` 로 최신 프로필을 가져온 뒤,
///   온보딩(생년월일·약관) 미완료면 온보딩 화면, 완료면 사용자가 설정한
///   기본 화면(`tamagochi` 또는 `todo`) 으로 진입.
///
/// 저장된 access token 이 만료된 채로 홈에 진입하더라도 첫 API 호출 시점에
/// [AuthInterceptor] 가 refresh 를 자동으로 시도한다. refresh 도 실패하면
/// `UnauthorizedException` 으로 떨어져 Welcome 으로 복귀.
/// 일시적 네트워크 오류는 사용자의 기본 화면으로 보수적 폴백 — 다음 부팅 때
/// 다시 잡힌다.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // 최소 노출 시간 — 깜빡임 방지 & 브랜드 각인용. 토큰 읽기 I/O 는 빠르게 끝나므로
    // 사용자에게 앱 로딩을 느끼게 하는 의도적 딜레이.
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    final tokens = await ref.read(authLocalDataSourceProvider).read();
    if (!mounted) return;

    if (tokens != null) {
      // 앱 재시작으로 세션이 복원되면 FCM 토큰도 다시 서버에 동기화해 둔다.
      // (디바이스 재부팅 / 앱 재설치 등으로 토큰이 바뀌었을 수 있음)
      // fire-and-forget — 네트워크 실패에도 메인 진입은 계속한다.
      unawaited(ref.read(fcmTokenRegistrarProvider).register());

      // 홈스크린 위젯에도 토큰 / API base URL 을 다시 채워준다.
      // 위젯은 별도 프로세스라 secure storage 에 직접 접근 못 함 — 앱이 부팅될 때마다
      // App Group UserDefaults 를 새로 갱신해줘야 위젯의 백그라운드 PATCH 가 동작한다.
      // 이미 로그인된 상태로 앱을 처음 띄울 때(=재로그인 안 거치는 경우) 도 sync 보장.
      unawaited(ref.read(widgetSyncServiceProvider).syncAuthTokens(
            accessToken: tokens.accessToken,
            refreshToken: tokens.refreshToken,
            apiBaseUrl: AppEnv.optional('API_BASE_URL'),
          ));

      // 토큰이 있어도 온보딩(생년월일/약관) 미완료면 메인 탭이 아니라 온보딩으로 보낸다.
      // GET /api/users/me 로 최신 플래그를 확인. 네트워크 일시 오류 시엔 사용자의
      // 기본 화면으로 보수적 폴백 — 다음 부팅 때 다시 잡힌다.
      try {
        final user = await ref.read(userRepositoryProvider).getMe();
        if (!mounted) return;
        ref.read(currentUserProvider.notifier).replace(user);
        context.go(resolvePostAuthDestination(ref, user));
      } on UnauthorizedException {
        // refresh 까지 실패한 상태 — AuthInterceptor 가 이미 로컬 토큰을 정리했을 것.
        if (!mounted) return;
        context.go(AppRoutes.welcome);
      } catch (_) {
        // 네트워크/일시적 서버 오류 — 일단 사용자 기본 화면으로 보낸다.
        if (!mounted) return;
        final defaultScreen = ref.read(defaultScreenProvider);
        final fallback = switch (defaultScreen) {
          DefaultScreen.home => AppRoutes.tamagochi,
          DefaultScreen.calendar => AppRoutes.todo,
        };
        context.go(fallback);
      }
    } else {
      context.go(AppRoutes.welcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pets, size: 80, color: colors.primary),
            const SizedBox(height: 16),
            Text(
              'doitdo',
              style: AppTextStyles.titleLarge.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
