import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:doitdo/core/errors/exceptions.dart';
import 'package:doitdo/core/utils/app_env.dart';
import 'package:doitdo/presentation/navigation/app_router.dart';
import 'package:doitdo/presentation/navigation/post_auth_destination.dart';
import 'package:doitdo/presentation/providers/app_data_providers.dart';
import 'package:doitdo/presentation/providers/current_user_provider.dart';
import 'package:doitdo/presentation/providers/default_screen_provider.dart';

/// 앱 부팅 직후 잠시 노출되는 스플래시 + **세션 복원 분기 지점**.
///
/// 디자인 의도:
/// - 0.0s: 네이티브 스플래시(흰 배경) 에서 인계 → 동일한 위치에 squircle 로고 표시
/// - 0.5s: 워드마크 "두잇뚜" 페이드 + 슬라이드업 (550ms)
/// - 0.75s: 태그라인 "오늘 할 일, 가볍게" 페이드 + 슬라이드업 (500ms)
/// - 1.0s: 로딩 도트 3개 페이드 인 (300ms) + 펄스 시작 (1.2s 루프)
/// - 1.8s: exit 페이드 아웃 (300ms) → 토큰 체크 결과에 따라 홈 / 웰컴 으로 전환
///
/// 핸드오프 원안은 0.95/1.15/1.4/1.8s 였으나 워드마크가 완전히 보이는 시간이
/// 0.3s 에 불과해 가시성이 너무 짧았다. 총 길이는 비슷하게 유지하면서 진입을
/// 0.45s 앞당겨 모두 보이는 구간을 ~0.8s 확보했다.
///
/// 토큰 I/O 는 애니메이션 타임라인과 병렬 진행 — 실제 라우팅은
/// "exit 페이드 아웃 완료" 와 "토큰 읽기 완료" 둘 다 충족된 시점에 발생.
///
/// 로고는 Flutter 측에서 직접 그리므로 Android 12+ 의 시스템 원형 마스크
/// 영향을 받지 않고 squircle 모양 그대로 표시된다.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with TickerProviderStateMixin {
  // ── 디자인 토큰 ──────────────────────────────────
  static const _bgColor = Color(0xFFFFFFFF);
  static const _logoOrange = Color(0xFFE07A2E);
  static const _ink = Color(0xFF231C16);
  static const _muted = Color(0xFF9A8E80);

  // 네이티브 스플래시 위치/크기 — 인계 시 점프 방지.
  static const _logoSize = 120.0;
  static const _yOffset = -40.0; // 정중앙에서 위로 살짝.

  // ── 타임라인 (ms) ─────────────────────────────
  // 핸드오프 원안(0.95/1.15/1.4/1.8s)은 네이티브 인계 후 워드마크가 다 뜨는
  // 시점이 1.5s, exit 가 1.8s 라 완전 노출 시간이 0.3s 에 불과해 가시성이
  // 매우 짧았다. 총 길이는 비슷하게 유지하되 진입을 0.45s 가량 앞당겨
  // "모두 보이는" 구간을 ~0.8s 확보한다.
  static const _wordmarkDelay = Duration(milliseconds: 500);
  static const _taglineDelay = Duration(milliseconds: 750);
  static const _dotsDelay = Duration(milliseconds: 1000);
  static const _exitDelay = Duration(milliseconds: 1800);
  static const _exitFadeDuration = Duration(milliseconds: 300);

  late final AnimationController _wordmarkController;
  late final AnimationController _taglineController;
  // 도트는 (a) 등장 페이드 (b) 무한 펄스 두 단계가 겹쳐있다.
  // 단일 컨트롤러로는 fade-in 표현이 안 돼서(0.4 floor 때문에 항상 보임)
  // appear/pulse 를 분리해 곱한다.
  late final AnimationController _dotsAppearController;
  late final AnimationController _dotsPulseController;
  // 1.8s 시점에 forward → 컨텐츠 전체를 페이드 아웃한 뒤 navigation.
  late final AnimationController _exitController;

  @override
  void initState() {
    super.initState();
    _wordmarkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _taglineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _dotsAppearController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _dotsPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _exitController = AnimationController(
      vsync: this,
      duration: _exitFadeDuration,
    );
    _bootstrap();
  }

  @override
  void dispose() {
    _wordmarkController.dispose();
    _taglineController.dispose();
    _dotsAppearController.dispose();
    _dotsPulseController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    // 애니메이션 스케줄링 — fire-and-forget.
    Future<void>.delayed(_wordmarkDelay, () {
      if (mounted) _wordmarkController.forward();
    });
    Future<void>.delayed(_taglineDelay, () {
      if (mounted) _taglineController.forward();
    });
    Future<void>.delayed(_dotsDelay, () {
      if (mounted) {
        _dotsAppearController.forward();
        _dotsPulseController.repeat();
      }
    });

    // 토큰 I/O 는 병렬 — 1.8s 마무리 직전에 결과 확인.
    final tokenFuture = ref.read(authLocalDataSourceProvider).read();

    await Future<void>.delayed(_exitDelay);
    if (!mounted) return;

    // exit 페이드 아웃 시작 + 토큰 대기. 둘 다 완료된 시점에 navigation.
    final fadeFuture = _exitController.forward();
    final tokens = await tokenFuture;
    await fadeFuture;
    if (!mounted) return;

    if (tokens != null) {
      // 앱 재시작으로 세션 복원되면 FCM 토큰 다시 동기화 (토큰 변경 가능성 대비).
      // 네트워크 실패에도 메인 진입은 계속 — fire-and-forget.
      unawaited(ref.read(fcmTokenRegistrarProvider).register());

      // 홈스크린 위젯이 별도 프로세스라 secure storage 에 직접 접근 못 함.
      // 앱 부팅 시마다 App Group UserDefaults 를 갱신해줘야 위젯 백그라운드 PATCH 동작.
      unawaited(ref.read(widgetSyncServiceProvider).syncAuthTokens(
            accessToken: tokens.accessToken,
            refreshToken: tokens.refreshToken,
            apiBaseUrl: AppEnv.optional('API_BASE_URL'),
          ));

      // 토큰이 있어도 온보딩(생년월일/약관) 미완료면 메인 탭이 아니라 온보딩으로 보낸다.
      // GET /api/users/me 로 최신 플래그를 확인. 네트워크 실패 시엔 보수적으로 메인으로
      // 보내도 무방하다 — 온보딩 화면은 결국 수동 호출도 가능한 구조라 다음 부팅에서 잡힌다.
      try {
        final user = await ref.read(userRepositoryProvider).getMe();
        if (!mounted) return;
        ref.read(currentUserProvider.notifier).replace(user);
        context.go(resolvePostAuthDestination(ref, user));
      } on UnauthorizedException {
        // refresh 실패 → 토큰이 더 이상 유효하지 않다. AuthInterceptor 가 이미 정리했으므로
        // Welcome 화면으로.
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
    return Scaffold(
      backgroundColor: _bgColor,
      // exit 페이드 아웃 — 컨텐츠 전체를 한 번에 사라지게 한다.
      // 배경(흰색)은 그대로 유지되어 다음 페이지로 자연스럽게 인계.
      body: AnimatedBuilder(
        animation: _exitController,
        builder: (context, child) {
          return Opacity(
            opacity: 1.0 - _exitController.value,
            child: child,
          );
        },
        child: SafeArea(
          child: Stack(
            children: [
            // ── 정중앙: 로고 + 워드마크 + 태그라인 ──
            Center(
              child: Transform.translate(
                offset: const Offset(0, _yOffset),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // squircle 모양 — ContinuousRectangleBorder 로 iOS 식 superellipse 클리핑.
                    // logo.svg 의 자체 라운드 코너(20%) 위에 더 둥근 곡선을 덮어
                    // 시스템 적응형 아이콘 마스크와 같은 시각으로 보이게 한다.
                    ClipPath(
                      clipper: const ShapeBorderClipper(
                        shape: ContinuousRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(50)),
                        ),
                      ),
                      child: SvgPicture.asset(
                        'assets/icons/logo.svg',
                        width: _logoSize,
                        height: _logoSize,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // 워드마크 "두잇뚜" — fade + 14px slide-up.
                    // 핸드오프 사양: 34px, weight 800, letter-spacing -0.03em (≈ -1.0 on 34).
                    // Pretendard 800 이 디자인 원본이지만 프로젝트 폰트는 GmarketSans 라
                    // GmarketSansBold (700) 로 폴백한다.
                    AnimatedBuilder(
                      animation: _wordmarkController,
                      builder: (_, __) {
                        final t = Curves.easeOutCubic
                            .transform(_wordmarkController.value);
                        return Opacity(
                          opacity: t,
                          child: Transform.translate(
                            offset: Offset(0, 14 * (1 - t)),
                            child: const Text(
                              '두잇뚜',
                              style: TextStyle(
                                fontFamily: 'GmarketSansBold',
                                fontSize: 34,
                                height: 1.0,
                                color: _ink,
                                letterSpacing: -1.0,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),

                    // 태그라인 "오늘 할 일, 가볍게" — 같은 fade + slide-up
                    AnimatedBuilder(
                      animation: _taglineController,
                      builder: (_, __) {
                        final t = Curves.easeOutCubic
                            .transform(_taglineController.value);
                        return Opacity(
                          opacity: t,
                          child: Transform.translate(
                            offset: Offset(0, 14 * (1 - t)),
                            child: const Text(
                              '오늘 할 일, 가볍게',
                              style: TextStyle(
                                fontFamily: 'GmarketSansMedium',
                                fontSize: 13,
                                height: 1.2,
                                color: _muted,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // ── 화면 하단 56px: 로딩 도트 3개 (orange 6px, gap 7, 1.2s 펄스) ──
            // appear (0→1, 300ms) 와 pulse (0..1 무한 반복) 두 컨트롤러를 함께 구독.
            Positioned(
              bottom: 56,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: Listenable.merge(
                  [_dotsAppearController, _dotsPulseController],
                ),
                builder: (_, __) {
                  final appear = Curves.easeOut
                      .transform(_dotsAppearController.value);
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      // 0.125 phase 시차 — 1.2s 사이클 기준 약 0.15s 차이.
                      final phase =
                          (_dotsPulseController.value - i * 0.125 + 1.0) %
                              1.0;
                      // 사인 펄스 — 0.4 ~ 1.0 사이.
                      final pulse =
                          0.5 + 0.5 * math.sin(2 * math.pi * phase);
                      final pulseOpacity = 0.4 + 0.6 * pulse;
                      // 등장 시 0 → pulseOpacity 로 페이드 인.
                      final opacity = pulseOpacity * appear;
                      return Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 3.5),
                        decoration: BoxDecoration(
                          color: _logoOrange.withValues(alpha: opacity),
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
