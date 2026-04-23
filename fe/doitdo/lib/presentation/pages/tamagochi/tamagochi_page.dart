import 'package:doitdo/core/utils/snap_scroll_physics.dart';
import 'package:doitdo/domain/entities/character.dart';
import 'package:doitdo/presentation/navigation/app_router.dart';
import 'package:doitdo/presentation/pages/tamagochi/character_view_model.dart';
import 'package:doitdo/presentation/pages/tamagochi/tamagochi_view_model.dart';
import 'package:doitdo/presentation/pages/tamagochi/widgets/character_card.dart';
import 'package:doitdo/presentation/pages/tamagochi/widgets/streak_section.dart';
import 'package:doitdo/presentation/widgets/common/todo_section.dart';
import 'package:doitdo/presentation/widgets/layouts/doitdo_full_layout.dart';
import 'package:doitdo/presentation/widgets/layouts/doitdo_scaffold.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// 다마고치 메인 홈.
class TamagochiPage extends ConsumerStatefulWidget {
  const TamagochiPage({super.key});

  @override
  ConsumerState<TamagochiPage> createState() => _TamagochiPageState();
}

class _TamagochiPageState extends ConsumerState<TamagochiPage> {
  // StreakSection 대략 높이 계산에 사용.
  // 수직 padding 16*2 + 타이틀 ~20 + gap 10 + (dot 22 + gap 4 + 날짜 label ~16) ≈ 104
  static const double _streakSectionHeight = 104;
  static const double _streakTopGap = 16;

  /// 헤더가 보이는 상태인지. 상태바 오버레이 + 아이콘 색 전환에만 쓰인다.
  /// 매 스크롤마다 build 가 다시 돌지 않도록 ValueNotifier 로 분리.
  final ValueNotifier<bool> _headerVisible = ValueNotifier<bool>(true);

  @override
  void initState() {
    super.initState();
    // 진입 시 캐릭터 조회 1회. 이미 로그인 플로우에서 ensureCharacter() 로 채워져
    // 있으면 load() 가 같은 값을 덮어쓸 뿐이라 부작용 없음.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(characterViewModelProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _headerVisible.dispose();
    super.dispose();
  }

  /// 알 10회 탭이 완료된 시점에 호출된다.
  /// 1) `/api/characters/me/hatch` 호출
  /// 2) 성공 시 이름짓기 페이지로 push
  /// 3) pop 후 캐릭터 재조회 (이름이 서버에 반영되어 내려오길 기대)
  Future<void> _handleHatch() async {
    final vm = ref.read(characterViewModelProvider.notifier);
    final ok = await vm.hatchEgg();
    if (!mounted) return;
    if (!ok) {
      _showComingSoon(context, '알을 깨우는 중에 문제가 발생했어요. 잠시 후 다시 시도해주세요.');
      return;
    }
    await context.push(AppRoutes.tamagochiNaming);
    if (!mounted) return;
    // 이름 저장 API 가 붙기 전까진 로컬 변경이 없으므로 재조회가 현재 상태를
    // 그대로 되돌려받는 안전한 액션이다.
    ref.read(characterViewModelProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tamagochiViewModelProvider);
    final vm = ref.read(tamagochiViewModelProvider.notifier);
    final characterAsync = ref.watch(characterViewModelProvider);

    // 에러 상태는 스낵바로 한 번만 노출하고 조용히 지나간다.
    ref.listen<AsyncValue<Character?>>(characterViewModelProvider,
        (prev, next) {
      next.whenOrNull(error: (err, _) {
        if (!mounted) return;
        _showComingSoon(context, '캐릭터 정보를 불러오지 못했어요. 잠시 후 다시 시도해주세요.');
      });
    });

    final character = characterAsync.valueOrNull;
    final isCharacterLoading = characterAsync.isLoading;
    final topInset = MediaQuery.paddingOf(context).top;

    final double headerHeight = 200.h +
        _streakTopGap +
        _streakSectionHeight;

    return ValueListenableBuilder<bool>(
      valueListenable: _headerVisible,
      builder: (context, visible, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: visible
              ? const SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: Brightness.light,
                  statusBarBrightness: Brightness.dark,
                )
              : const SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: Brightness.dark,
                  statusBarBrightness: Brightness.light,
                ),
          child: child!,
        );
      },
      child: DoitdoScaffold(
        useSafeArea: false,
        body: DoitdoFullLayout(
          child: Stack(
            children: [
              // 1. 스크롤 본문. 상태바 영역은 피해 topInset 아래에서 시작한다.
              //    스크롤 중에도 이 패딩은 상수 — 울렁임의 원천(가변 패딩)을 제거.
              Padding(
                padding: EdgeInsets.only(top: topInset),
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification.metrics.axis != Axis.vertical) return false;
                    final nowVisible =
                        notification.metrics.pixels < headerHeight / 2;
                    if (_headerVisible.value != nowVisible) {
                      _headerVisible.value = nowVisible;
                    }
                    return false;
                  },
                  child: CustomScrollView(
                    physics: SnapScrollPhysics(snapOffset: headerHeight),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            CharacterCard(
                              state: state,
                              character: character,
                              isCharacterLoading: isCharacterLoading,
                              onTapShop: () => _showComingSoon(
                                context,
                                '상점 기능은 아직 준비 중이에요.',
                              ),
                              onTapCollection: () =>
                                  context.push(AppRoutes.tamagochiCollection),
                              onHatch: _handleHatch,
                            ),
                            SizedBox(height: _streakTopGap),
                            StreakSection(
                              streakDays: state.streakDays,
                              slots: state.streakSlots,
                              slotDates: state.streakSlotDates,
                            ),
                          ],
                        ),
                      ),
                      SliverLayoutBuilder(
                        builder: (context, constraints) {
                          return SliverToBoxAdapter(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.viewportMainAxisExtent,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    TodoSection(
                                      title: '오늘의 할 일',
                                      actionLabel: '추가하기',
                                      onActionTap: () {
                                        // TODO: 할 일 추가 플로우 연결
                                      },
                                      todos: state.todayTodos,
                                      onToggle: vm.toggleTodayTodo,
                                    ),
                                    const SizedBox(height: 24),
                                    TodoSection(
                                      title: '언젠가 할 일',
                                      actionLabel: '추가하기',
                                      onActionTap: () {
                                        // TODO: 할 일 추가 플로우 연결
                                      },
                                      todos: state.somedayTodos,
                                      onToggle: vm.toggleSomedayTodo,
                                    ),
                                  ],
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

              // 2. 상단 시스템바 오버레이.
              //    Mode 1 (헤더 보임) → grass 이미지 노출: 캐릭터 카드가 상태바까지 이어진 인상.
              //    Mode 2 (헤더 사라짐) → scaffold 배경색: 할 일 리스트가 상태바와 겹치는 것을 차단.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: topInset,
                child: _StatusBarTint(visible: _headerVisible),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 아직 구현되지 않은 기능을 탭했을 때 띄우는 짧은 스낵바.
void _showComingSoon(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
}

/// 상태바 영역을 덮는 고정 오버레이.
class _StatusBarTint extends StatelessWidget {
  const _StatusBarTint({required this.visible});

  final ValueListenable<bool> visible;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: Theme.of(context).scaffoldBackgroundColor),
        ValueListenableBuilder<bool>(
          valueListenable: visible,
          builder: (context, isVisible, _) {
            return AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isVisible ? 1.0 : 0.0,
              child: Image.asset(
                'assets/images/bg_grass.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                filterQuality: FilterQuality.none,
              ),
            );
          },
        ),
      ],
    );
  }
}
