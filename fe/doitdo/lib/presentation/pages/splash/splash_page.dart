import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:doitdo/core/config/app_config.dart';
import 'package:doitdo/core/errors/exceptions.dart';
import 'package:doitdo/domain/entities/auth_tokens.dart';
import 'package:doitdo/domain/entities/room_placement.dart';
import 'package:doitdo/presentation/navigation/app_router.dart';
import 'package:doitdo/presentation/navigation/post_auth_destination.dart';
import 'package:doitdo/presentation/pages/tamagochi/character_view_model.dart';
import 'package:doitdo/presentation/pages/tamagochi/my_room_provider.dart';
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
/// 토큰 I/O 는 애니메이션 타임라인과 병렬 진행 — 실제 라우팅은
/// "exit 페이드 아웃 완료" 와 "토큰 읽기 완료" 둘 다 충족된 시점에 발생.
///
/// 토큰이 있을 땐 `GET /api/users/me` 로 최신 프로필을 가져온 뒤 온보딩 플래그
/// (`birthDateRegistered`, `agreementsAccepted`) 에 따라 다음 라우트를 결정한다.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key, this.fromWidget = false});

  /// 홈스크린 위젯에서 진입할 때 true — 스플래시 애니메이션을 건너뛰고 즉시 라우팅.
  final bool fromWidget;

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
  static const _wordmarkDelay = Duration(milliseconds: 500);
  static const _taglineDelay = Duration(milliseconds: 750);
  static const _dotsDelay = Duration(milliseconds: 1000);
  static const _exitDelay = Duration(milliseconds: 1800);

  late final AnimationController _wordmarkController;
  late final AnimationController _taglineController;
  // 도트는 (a) 등장 페이드 (b) 무한 펄스 두 단계가 겹쳐있다.
  // 단일 컨트롤러로는 fade-in 표현이 안 돼서(0.4 floor 때문에 항상 보임)
  // appear/pulse 를 분리해 곱한다.
  late final AnimationController _dotsAppearController;
  late final AnimationController _dotsPulseController;

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
    _bootstrap();
  }

  @override
  void dispose() {
    _wordmarkController.dispose();
    _taglineController.dispose();
    _dotsAppearController.dispose();
    _dotsPulseController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final tokenFuture = ref.read(authLocalDataSourceProvider).read();

    if (widget.fromWidget) {
      // 위젯 진입: 애니메이션 생략.
      //
      // 앱이 살아있는 경우(background→foreground): currentUserProvider 에 이미 유저가
      // 로드되어 있다. 이때 getMe() 를 다시 호출하면 불필요한 네트워크 왕복(300-500ms)
      // 이 발생하고, SplashPage 가 표시되는 동안 StatefulShellRoute(shell) 이 unmount 되어
      // todoViewModelProvider(autoDispose) 가 소멸 → fetchTodos abandoned → 위젯에서
      // 완료한 항목이 앱에 반영되지 않는 버그로 이어진다.
      //
      // currentUser 가 이미 있으면 getMe() 없이 즉시 라우팅 — AppLifecycleState.resumed
      // 에서 호출된 fetchTodos 가 shell 이 살아있는 상태에서 정상 동작한다.
      final existingUser = ref.read(currentUserProvider).valueOrNull;
      if (existingUser != null) {
        if (!mounted) return;
        context.go(resolvePostAuthDestination(ref, existingUser));
        return;
      }
      // 콜드스타트 또는 미로그인 — 토큰 확인 후 인증 플로우.
      final tokens = await tokenFuture;
      if (!mounted) return;
      await _navigateFromTokens(tokens);
      return;
    }

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

    // ── 네트워크 I/O 를 애니메이션과 병렬로 시작 ────────────────────────
    // 종전엔 애니메이션 1.8초가 끝난 뒤에야 getMe / character / room 호출이
    // 시작돼 그 시간을 못 썼다. 이제 토큰이 도착하는 즉시 getMe + prime 을
    // 발화 — 사용자가 splash 모션을 보는 사이 대부분의 작업이 완료된다.
    // 반환값 = navigate 할 라우트. context.go 호출만 애니메이션 종료 이후에 한다.
    final destinationFuture =
        tokenFuture.then((tokens) => _resolveAuthDestination(tokens));

    await Future<void>.delayed(_exitDelay);
    if (!mounted) return;

    // 종전에는 splash 자체 exit 페이드(300ms) 를 돌린 뒤 context.go 를 호출했는데,
    // 그 후 go_router 의 기본 페이지 트랜지션(~300ms) 이 다시 깔려 "흰 화면" 이
    // 잠깐 보이는 인상이 있었다. splash 페이드를 제거하고 라우터 트랜지션 하나로
    // 합치면 splash → app 전환이 한 번에 자연스럽게 이어진다.
    final destination = await destinationFuture;
    if (!mounted) return;

    context.go(destination);
  }

  /// 토큰을 받아 다음 라우트를 결정 + side effect (FCM 등록, prime, currentUser
  /// 갱신) 까지 한 번에 처리. _bootstrap 의 정상 경로에서 애니메이션과 병렬로
  /// 진행되도록 결과만 string 으로 반환한다.
  ///
  /// **getMe 와 prime 을 병렬로** — getMe 는 라우팅 결정에 필수지만 prime
  /// (character / room / 이미지 사전 로딩) 은 getMe 결과를 안 쓴다. 즉시
  /// kick-off 해서 getMe 의 ~200ms latency 를 prime 시간으로 흡수.
  Future<String> _resolveAuthDestination(AuthTokens? tokens) async {
    if (tokens == null) {
      return AppRoutes.welcome;
    }
    unawaited(ref.read(widgetSyncServiceProvider).syncAuthTokens(
          accessToken: tokens.accessToken,
          refreshToken: tokens.refreshToken,
          apiBaseUrl: AppConfig.apiBaseUrl,
        ));
    // prime 을 getMe 와 동시 시작.
    unawaited(_primeTamagochiVisuals());
    try {
      final user = await ref.read(userRepositoryProvider).getMe();
      if (!mounted) return AppRoutes.welcome;
      ref.read(currentUserProvider.notifier).replace(user);
      unawaited(ref.read(fcmTokenRegistrarProvider).register());
      return resolvePostAuthDestination(ref, user);
    } on UnauthorizedException {
      return AppRoutes.welcome;
    } catch (_) {
      final defaultScreen = ref.read(defaultScreenProvider);
      return switch (defaultScreen) {
        DefaultScreen.home => AppRoutes.tamagochi,
        DefaultScreen.calendar => AppRoutes.todo,
      };
    }
  }

  Future<void> _navigateFromTokens(AuthTokens? tokens) async {
    if (tokens != null) {
      // 홈스크린 위젯이 별도 프로세스라 secure storage 에 직접 접근 못 함.
      // 앱 부팅 시마다 App Group UserDefaults 를 갱신해줘야 위젯 백그라운드 PATCH 동작.
      unawaited(ref.read(widgetSyncServiceProvider).syncAuthTokens(
            accessToken: tokens.accessToken,
            refreshToken: tokens.refreshToken,
            apiBaseUrl: AppConfig.apiBaseUrl,
          ));

      // 토큰이 있어도 온보딩(생년월일/약관) 미완료면 메인 탭이 아니라 온보딩으로 보낸다.
      // GET /api/users/me 로 최신 플래그를 확인. 네트워크 일시 오류 시엔 사용자의
      // 기본 화면으로 보수적 폴백 — 다음 부팅 때 다시 잡힌다.
      try {
        final user = await ref.read(userRepositoryProvider).getMe();
        if (!mounted) return;
        ref.read(currentUserProvider.notifier).replace(user);
        // getMe() 성공 = 세션 유효 확인 후 FCM 등록 — 401 없이 안전하게 등록.
        unawaited(ref.read(fcmTokenRegistrarProvider).register());
        // 다마고치 홈 visual 사전 prime — character + room 조회와 이미지 precache 를
        // 백그라운드로 시작. 사용자가 splash 애니메이션을 보는 동안 디스크 캐시까지
        // 채워둬, tamagochi 진입 직후 캐릭터/가구가 즉시 그려지도록 한다.
        unawaited(_primeTamagochiVisuals());
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

  /// 다마고치 홈 visual prime — character + room 데이터 fetch 후 thumbnailUrl /
  /// 가구 imageUrl 들을 모두 [CachedNetworkImageProvider] 로 사전 디코드한다.
  ///
  /// 결과:
  ///   - [characterViewModelProvider] (non-autoDispose) 상태가 채워져 tamagochi
  ///     진입 시 캐릭터 데이터가 이미 거기 있다.
  ///   - [myRoomProvider] (non-autoDispose) 도 마찬가지로 prime — 가구 list 가
  ///     캐시되어 진입 즉시 그려진다.
  ///   - 모든 이미지가 디스크 캐시에 적재되어 네트워크 왕복 없이 그려진다.
  ///
  /// 실패는 모두 무시 — 다마고치 페이지가 자체적으로 다시 fetch / load 한다.
  /// fire-and-forget 으로 호출되며 splash 애니메이션과 병렬 진행.
  Future<void> _primeTamagochiVisuals() async {
    try {
      final characterFuture =
          ref.read(characterViewModelProvider.notifier).ensureCharacter();
      final roomFuture = ref.read(myRoomProvider.future).catchError(
        (_) => const <RoomFurniturePlacement>[],
      );
      await Future.wait<Object?>([characterFuture, roomFuture]);

      if (!mounted) return;
      final character = ref.read(characterViewModelProvider).valueOrNull;
      final room = ref.read(myRoomProvider).valueOrNull ??
          const <RoomFurniturePlacement>[];
      final urls = <String>{
        if (character != null && character.thumbnailUrl.isNotEmpty)
          character.thumbnailUrl,
        for (final item in room)
          if (item.imageUrl.isNotEmpty) item.imageUrl,
      };
      await Future.wait(urls.map(_precacheUrl));
    } catch (_) {
      // prime 은 best-effort — 모든 실패는 무시.
    }
  }

  /// 단일 URL 을 [CachedNetworkImageProvider] 로 미리 디코드. 실패는 swallow.
  Future<void> _precacheUrl(String url) async {
    final completer = Completer<void>();
    final stream =
        CachedNetworkImageProvider(url).resolve(ImageConfiguration.empty);
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (_, _) {
        stream.removeListener(listener);
        if (!completer.isCompleted) completer.complete();
      },
      onError: (_, _) {
        stream.removeListener(listener);
        if (!completer.isCompleted) completer.complete();
      },
    );
    stream.addListener(listener);
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      // splash 자체 exit 페이드는 제거 — go_router 의 페이지 트랜지션 하나만으로
      // splash → app 전환이 자연스럽게 이어진다. 종전엔 두 페이드가 직렬로
      // 일어나 "흰 화면" 이 잠깐 보이는 인상이 있었다.
      body: SafeArea(
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
                      // fontFamily 미명시 — ThemeData.fontFamily(사용자 선택) 따라감.
                      // weight 700 으로 weight 메타데이터 기반 자동 선택.
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
                                  fontWeight: FontWeight.w700,
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
                                  fontWeight: FontWeight.w500,
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
    );
  }
}
