import 'package:doitdo/core/utils/snap_scroll_physics.dart';
import 'package:doitdo/domain/entities/character.dart';
import 'package:doitdo/presentation/models/todo.dart';
import 'package:doitdo/presentation/navigation/app_router.dart';
import 'package:doitdo/presentation/pages/tamagochi/character_view_model.dart';
import 'package:doitdo/presentation/pages/tamagochi/tamagochi_view_model.dart';
import 'package:doitdo/presentation/pages/tamagochi/widgets/character_card.dart';
import 'package:doitdo/presentation/pages/tamagochi/widgets/streak_section.dart';
import 'package:doitdo/presentation/pages/todo/todo_view_model.dart';
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
    // 진입 시 캐릭터 조회 + 미수령이면 자동 POST. 로그인 플로우에서는 이쪽만
    // 돌리고 welcome_page 에서는 띄우지 않아, 두 경로 load() 가 경쟁하다
    // "GET 실패 → POST" 판정이 덮이는 상황을 막는다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(characterViewModelProvider.notifier).ensureCharacter();
      // todoViewModelProvider 는 팀원이 사용하는 TODO provider 를 그대로 공유.
      // 탭 전환 시 유지되지만 최초 진입일 수 있으므로, 비어있을 때만 초기 로드.
      // TODO(BE): 팀원이 /api/todos 를 붙이면 loadDummyTodos 호출도 교체된다.
      final todoState = ref.read(todoViewModelProvider);
      if (todoState.allTodos.isEmpty && todoState.allSomedayTodos.isEmpty) {
        ref.read(todoViewModelProvider.notifier).loadDummyTodos();
      }
    });
  }

  @override
  void dispose() {
    _headerVisible.dispose();
    super.dispose();
  }

  /// 홈 알 탭 → 부화 페이지 push.
  ///
  /// 부화 페이지 내부에서 10회 탭 완료 → hatch API → 이름짓기 페이지로
  /// pushReplacement 된다. 이름짓기까지 끝나고 홈으로 pop 된 시점에 이 await 가
  /// 끝나므로 여기서 load() 로 최신 상태 재조회.
  Future<void> _handleEggTap() async {
    await context.push(AppRoutes.tamagochiHatch);
    if (!mounted) return;
    ref.read(characterViewModelProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tamagochiViewModelProvider);
    final characterAsync = ref.watch(characterViewModelProvider);
    final todoState = ref.watch(todoViewModelProvider);
    final todoVm = ref.read(todoViewModelProvider.notifier);

    // 오늘 날짜에 해당하는 할 일만 필터. range 타입도 오늘 포함이면 노출.
    final today = DateTime.now();
    final todayTodos = todoState.allTodos
        .where((t) => _isTodayTodo(t, today))
        .toList(growable: false);
    final somedayTodos = todoState.allSomedayTodos;

    // 에러 스낵바 + 성장률 100 → 자동 진화 트리거. 두 작업 모두 character 상태
    // 변화에 반응하므로 같은 ref.listen 에 묶는다. 진화는 알/미확정 단계에서는
    // 의미 없고, 이미 100 이었던 상태에서 재렌더될 때 중복 호출되지 않도록
    // "이전 값이 100 미만이었다가 100 이 된 순간" 만 트리거한다.
    ref.listen<AsyncValue<Character?>>(characterViewModelProvider,
        (prev, next) {
      next.whenOrNull(error: (err, _) {
        if (!mounted) return;
        _showComingSoon(context, '캐릭터 정보를 불러오지 못했어요. 잠시 후 다시 시도해주세요.');
      });

      final prevChar = prev?.valueOrNull;
      final nextChar = next.valueOrNull;
      if (nextChar == null || nextChar.isEgg) return;
      if (nextChar.growthPercent < 100) return;
      final wasAlreadyFull =
          prevChar != null && prevChar.growthPercent >= 100;
      if (wasAlreadyFull) return;
      ref
          .read(characterViewModelProvider.notifier)
          .evolve(nextChar.userCharacterId);
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
                              onEggTap: _handleEggTap,
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
                                      todos: todayTodos,
                                      onToggle: todoVm.toggleTodo,
                                    ),
                                    const SizedBox(height: 24),
                                    TodoSection(
                                      title: '언젠가 할 일',
                                      actionLabel: '추가하기',
                                      onActionTap: () {
                                        // TODO: 할 일 추가 플로우 연결
                                      },
                                      todos: somedayTodos,
                                      onToggle: todoVm.toggleSomedayTodo,
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

/// 해당 Todo 가 "오늘의 할 일" 에 포함되는지. 단일 날짜는 동일 일자, 기간은 오늘이
/// 시작~종료 사이, 반복은 시작일이 오늘 이전이고 종료일이 없거나 오늘 이후면 포함.
bool _isTodayTodo(Todo todo, DateTime today) {
  bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  bool onOrBefore(DateTime a, DateTime b) =>
      a.isBefore(b) || sameDay(a, b);

  switch (todo.dateType) {
    case TodoDateType.normal:
      return todo.date != null && sameDay(todo.date!, today);
    case TodoDateType.range:
      final start = todo.rangeStart;
      final end = todo.rangeEnd;
      if (start == null) return false;
      if (!onOrBefore(start, today)) return false;
      if (end == null) return true;
      return onOrBefore(today, end);
    case TodoDateType.repeat:
      final start = todo.repeatStartDate;
      final end = todo.repeatEndDate;
      if (start == null) return false;
      if (!onOrBefore(start, today)) return false;
      if (end == null) return true;
      return onOrBefore(today, end);
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
