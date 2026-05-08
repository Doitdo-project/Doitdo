import 'dart:async';

import 'package:doitdo/core/utils/snap_scroll_physics.dart';
import 'package:doitdo/domain/entities/character.dart';
import 'package:doitdo/domain/entities/streak.dart';
import 'package:doitdo/presentation/models/todo.dart';
import 'package:doitdo/presentation/navigation/app_router.dart';
import 'package:doitdo/presentation/pages/tamagochi/character_view_model.dart';
import 'package:doitdo/presentation/pages/tamagochi/streak_view_model.dart';
import 'package:doitdo/presentation/pages/tamagochi/tamagochi_state.dart';
import 'package:doitdo/presentation/pages/tamagochi/tamagochi_view_model.dart';
import 'package:doitdo/presentation/pages/tamagochi/widgets/character_card.dart';
import 'package:doitdo/presentation/pages/tamagochi/widgets/evolution_overlay.dart';
import 'package:doitdo/presentation/pages/tamagochi/widgets/status_pill.dart';
import 'package:doitdo/presentation/pages/todo/todo_state.dart';
import 'package:doitdo/presentation/pages/todo/todo_view_model.dart';
import 'package:doitdo/presentation/pages/todo/widgets/todo_add_sheet.dart';
import 'package:doitdo/presentation/pages/todo/widgets/todo_detail_sheet.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_dialog.dart';
import 'package:doitdo/presentation/widgets/common/todo_item_card.dart';
import 'package:doitdo/presentation/providers/home_scroll_provider.dart';
import 'package:doitdo/presentation/widgets/layouts/doitdo_full_layout.dart';
import 'package:doitdo/presentation/widgets/layouts/doitdo_scaffold.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
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
  /// 캐릭터 카드 + 상태 알약을 합친 시각적 헤더 높이의 근사치.
  /// StatusPill 이 카드 하단을 -16.h 만큼 침범하면서 ~50.h 노출되므로
  /// 카드 본체(260.h) + ~34.h ≈ 294.h. snap / 상태바 토글 임계만 잡으면 되니
  /// 정확하지 않아도 무방.
  static const double _headerHeightExclTopInset = 294;

  /// 헤더가 보이는 상태인지. 상태바 오버레이 + 아이콘 색 전환에만 쓰인다.
  /// 매 스크롤마다 build 가 다시 돌지 않도록 ValueNotifier 로 분리.
  final ValueNotifier<bool> _headerVisible = ValueNotifier<bool>(true);

  late final ScrollController _scrollController;

  /// farewell API 호출 in-flight 여부. 뱃지 중복 탭 방지용.
  bool _farewelling = false;

  /// 진화 플로우 진행 중 여부. evolve API 호출 시작부터 진화 연출 overlay 종료까지
  /// true 로 유지된다. 뱃지 중복 탭 방지 + CharacterCard 의 hideCharacter 트리거 겸용.
  bool _evolving = false;

  /// 스트릭 보상 수령 API in-flight 여부. 버튼 중복 탭 방지 + 버튼 스피너용.
  bool _claimingReward = false;

  @override
  void initState() {
    super.initState();
    // 진입 시 캐릭터 조회 + 미수령이면 자동 POST. 로그인 플로우에서는 이쪽만
    // 돌리고 welcome_page 에서는 띄우지 않아, 두 경로 load() 가 경쟁하다
    // "GET 실패 → POST" 판정이 덮이는 상황을 막는다.
    //
    // TodoViewModel 은 생성자에서 fetchTodos() 를 자동 호출하므로 홈에서
    // 별도 부트스트랩은 불필요 — build 안 ref.watch 만으로 초기 로드됨.
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(homeScrollControllerProvider.notifier).state = _scrollController;
      ref.read(characterViewModelProvider.notifier).ensureCharacter();
    });
  }

  @override
  void dispose() {
    // dispose 안에서 homeScrollControllerProvider 를 null 로 클리어하던 코드는
    // 의도적으로 제거했다. 이 widget 이 unmount 되는 시점은 항상 위젯 트리
    // finalize 중이고 — ConsumerStatefulElement 는 이미 disposed 라 ref.read 가
    // 어설션이며, notifier 참조를 잡아두고 state= 를 호출해도 listener notify 가
    // finalize 중인 트리에 흘러들어가 GlobalKey duplicate / Element activate 등의
    // cascade 어설션을 일으킨다.
    // homeScrollControllerProvider 는 non-autoDispose 이므로 stale reference 가
    // 한 개 남는 것뿐이고, doitdo_shell._onTap 이 controller.hasClients 로 안전하게
    // 검사한 후 폴백한다 (다음 TamagochiPage 가 mount 될 때 새 controller 로 덮어쓴다).
    _scrollController.dispose();
    _headerVisible.dispose();
    super.dispose();
  }

  /// Todo 완료 후 exp 반영을 기다렸다가 캐릭터 상태를 조용히 재조회한다.
  ///
  /// BE 가 `AFTER_COMMIT` 리스너로 비동기 exp 지급을 하기 때문에 곧장 GET 하면
  /// 옛 값을 받을 가능성이 있다. 우선 200ms 뒤 1차 조회, currentExp 가 그대로면
  /// 아직 커밋이 안 끝났다고 보고 500ms 뒤 한 번 더.
  ///
  /// UI 에 로딩 스피너가 튀면 화면이 깜빡이기 때문에 [CharacterViewModel.refresh]
  /// 를 사용한다 (state 를 loading 으로 전환하지 않고 성공 시에만 data 갱신).
  ///
  /// 같은 트리거(=오늘 첫 todo 완료) 에 스트릭도 적립되므로 캐릭터 1차 조회와
  /// 함께 스트릭도 silent refresh — 별도 폴링 없이 한 번이면 충분하다고 가정.
  Future<void> _refreshCharacterAfterTodoDone() async {
    final vm = ref.read(characterViewModelProvider.notifier);
    final beforeExp =
        ref.read(characterViewModelProvider).valueOrNull?.currentExp;

    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    await vm.refresh();
    unawaited(ref.read(streakViewModelProvider.notifier).refresh());
    if (!mounted) return;

    final afterFirst =
        ref.read(characterViewModelProvider).valueOrNull?.currentExp;
    if (afterFirst != beforeExp) return;

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    await vm.refresh();
  }

  /// 오늘/언젠가 할 일 섹션의 "추가하기" 버튼이 눌릴 때 띄우는 바텀시트.
  /// Todo 페이지와 동일한 `TodoAddSheet` 를 사용한다.
  ///
  /// - `date == null` : "언젠가 할 일" 로 추가 (날짜 없음)
  /// - `date != null` : 해당 날짜(보통 오늘) 의 "오늘의 할 일" 로 추가
  void _openAddSheet(BuildContext context, DateTime? date) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (_) => TodoAddSheet(initialDate: date),
    );
  }

  void _openDetailSheet(BuildContext context, Todo todo, bool isSomeday) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (_) => TodoDetailSheet(todo: todo, isSomeday: isSomeday),
    );
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

  /// 독립 뱃지 탭. 확인 다이얼로그로 한 번 감싼 뒤 farewell API 호출.
  /// 성공 시 서버가 다음 알을 자동 배정하므로 ViewModel 이 load() 로 갱신.
  Future<void> _handleFarewellTap() async {
    if (_farewelling) return;
    final character =
        ref.read(characterViewModelProvider).valueOrNull;
    final name =
        (character == null || character.name.isEmpty) ? '다마고치' : character.name;
    final confirmed = await showDoitdoDialog(
      context: context,
      title: '독립 시키기',
      message: '$name가 떠날 준비가 됐어요.\n'
          '배웅하면 되돌릴 수 없고 바로 새 알이 도착해요.',
      confirmLabel: '배웅하기',
      cancelLabel: '취소',
    );
    if (!mounted || confirmed != true) return;

    setState(() => _farewelling = true);
    final ok =
    await ref.read(characterViewModelProvider.notifier).farewell();
    if (!mounted) return;
    setState(() => _farewelling = false);

    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(ok ? '독립 완료! 새 알이 도착했어요.' : '독립 처리 중 문제가 생겼어요. 다시 시도해주세요.'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  /// 진화 뱃지 탭. 확인 다이얼로그 → evolve API → 성공 시 풀스크린 진화 연출
  /// overlay. 자동 진화 흐름은 제거되어 사용자가 직접 트리거 해야 BABY→TEEN /
  /// TEEN→ADULT 가 진행된다.
  ///
  /// overlay 의 silhouette 단계에서 사용할 진화 직전 thumbnailUrl 은 evolve
  /// 호출 직전에 캡처해둔다 — evolve 안에서 백그라운드 refresh 가 트리거되어
  /// state 가 새 캐릭터로 갱신되면 character.thumbnailUrl 이 이미 새 url 로
  /// 바뀌어 있을 수 있기 때문.
  Future<void> _handleEvolveTap() async {
    if (_evolving) return;
    final character =
        ref.read(characterViewModelProvider).valueOrNull;
    if (character == null) return;

    final name = character.name.isEmpty ? '다마고치' : character.name;
    final confirmed = await showDoitdoDialog(
      context: context,
      title: '진화 시키기',
      message: '$name가 다음 단계로 진화할 준비가 됐어요.\n'
          '진화하면 모습이 바뀌고 다시 처음부터 자라요.',
      confirmLabel: '진화시키기',
      cancelLabel: '취소',
    );
    if (!mounted || confirmed != true) return;

    final beforeImageUrl = character.thumbnailUrl;
    final beforeStage = character.rawStage;

    // _evolving=true → CharacterCard 가 캐릭터+말풍선을 페이드아웃 시켜
    // 빈 방으로 만든다. 이 상태에서 API 호출 → refresh → overlay 까지 진행하므로
    // dim 사이로 옛/새 캐릭터가 비치는 일이 없고, overlay 닫힘과 동시에 새
    // 캐릭터로 페이드인 된다.
    setState(() => _evolving = true);
    final evolution = await ref
        .read(characterViewModelProvider.notifier)
        .evolve(character.userCharacterId);
    if (!mounted) return;

    if (evolution == null) {
      setState(() => _evolving = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('진화 처리 중 문제가 생겼어요. 다시 시도해주세요.'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      return;
    }

    // home 이 가려진 동안 새 캐릭터로 silent refresh — overlay 진행 ~5초 안에
    // 갱신이 끝나, overlay 닫힘 후 페이드인 시점엔 이미 새 캐릭터로 그려진다.
    ref.read(characterViewModelProvider.notifier).refresh();

    await EvolutionOverlay.show(
      context,
      beforeImageUrl: beforeImageUrl,
      animationUrl: evolution.animationUrl,
      afterImageUrl: evolution.characterImageUrl,
      beforeStage: beforeStage,
      afterStage: evolution.afterStage,
    );

    if (!mounted) return;
    setState(() => _evolving = false);
  }

  /// 7일 블록 완성 시 노출되는 "🎁 보상 받기" 탭 핸들러.
  /// BE 가 이미 수령된 케이스를 `rewarded=false` 로 회신하므로 분기해서 안내.
  Future<void> _handleClaimReward() async {
    if (_claimingReward) return;
    setState(() => _claimingReward = true);
    final reward = await ref
        .read(streakViewModelProvider.notifier)
        .claimReward();
    if (!mounted) return;
    setState(() => _claimingReward = false);

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    if (reward == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('보상 수령 중 문제가 생겼어요. 잠시 후 다시 시도해주세요.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          reward.rewarded
              ? '🎉 ${reward.streakCount}일 연속 달성! +${reward.rewardAmount}코인'
              : '이미 보상을 받았어요.',
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tamagochiViewModelProvider);
    final characterAsync = ref.watch(characterViewModelProvider);
    final streakAsync = ref.watch(streakViewModelProvider);
    final todoState = ref.watch(todoViewModelProvider);
    final todoVm = ref.read(todoViewModelProvider.notifier);

    // 스트릭은 네트워크 실패 / 로딩 중에는 0/빈 윈도우로 fallback (홈을 막지 않는다).
    final streak = streakAsync.valueOrNull ?? Streak.empty;
    final today = DateTime.now();
    final streakWindow = TamagochiState.buildStreakWindow(
      streakDays: streak.currentCount,
      streakStartDate: streak.currentStartDate,
      today: today,
    );

    // 오늘 날짜에 해당하는 할 일만 필터. range 타입도 오늘 포함이면 노출.
    final todayTodos = todoState.allTodos
        .where((t) => _isTodayTodo(t, today))
        .toList(growable: false);
    final somedayTodos = todoState.allSomedayTodos;

    // 캐릭터 fetch 에러 스낵바. 진화 트리거는 더 이상 자동이 아님 — 캐릭터
    // 카드의 액션 뱃지(canEvolve/canFarewell) 탭 → 다이얼로그 흐름으로 대체됨.
    ref.listen<AsyncValue<Character?>>(characterViewModelProvider,
            (prev, next) {
          // 첫 로드(loading→error) 는 dio 의 토큰 refresh / 자동 재시도가 끼어들면서
          // 잠깐 error 로 빠졌다 곧 회복되는 경우가 많다. 깜빡 떴다 사라지는 스낵바를
          // 막기 위해, "한 번이라도 데이터를 보여준 적이 있는데 다시 실패" 한 경우
          // (= data → error regression) 에만 알림. 진짜 영구 실패는 캐릭터 카드의
          // 빈 상태 UI 가 처리하므로 사용자가 모르고 지나치진 않는다.
          final wasShowingData =
              prev != null && prev.hasValue && prev.value != null;
          if (next.hasError && wasShowingData && mounted) {
            _showComingSoon(context, '캐릭터 정보를 불러오지 못했어요. 잠시 후 다시 시도해주세요.');
          }
        });

    // 타마고치 탭 진입 시 스트릭 silent refresh.
    ref.listen<int>(tamagochiEnterTriggerProvider, (_, __) {
      ref.read(streakViewModelProvider.notifier).refresh();
    });

    // Todo 완료 count 가 증가하면 exp 가 올라갔을 가능성이 있으므로 캐릭터 재조회.
    // 새로 isDone=true 로 전환된 todoId 가 있을 때만 발화 — _doneCount 비교는
    // TODO 생성(addTodo) 시 state 교체 타이밍에도 발화할 수 있어 done-id 집합
    // 차분으로 "실제로 완료된 항목이 늘었는지" 를 정확히 판별한다.
    // BE 는 AFTER_COMMIT 리스너로 exp 를 비동기 부여하므로 곧장 GET /me 를 부르면
    // 옛 값을 받을 수 있다. 200ms 먼저 조회해보고 exp 변화가 없으면 500ms 뒤 한 번 더.
    ref.listen<TodoState>(todoViewModelProvider, (prev, next) {
      if (prev == null) return;
      final prevDoneIds = {
        ...prev.allTodos.where((t) => t.isDone).map((t) => t.id),
        ...prev.allSomedayTodos.where((t) => t.isDone).map((t) => t.id),
      };
      final nextDoneIds = {
        ...next.allTodos.where((t) => t.isDone).map((t) => t.id),
        ...next.allSomedayTodos.where((t) => t.isDone).map((t) => t.id),
      };
      if (nextDoneIds.difference(prevDoneIds).isNotEmpty) {
        _refreshCharacterAfterTodoDone();
      }
    });

    final character = characterAsync.valueOrNull;
    final isCharacterLoading = characterAsync.isLoading;
    final topInset = MediaQuery.paddingOf(context).top;

    final double headerHeight = _headerHeightExclTopInset.h + topInset;

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
              // 1. 스크롤 본문. 캐릭터 카드가 상태바 영역까지 배경(grass)을 확장하므로
              //    여기서는 top padding 을 주지 않고 Card 내부에서 topSafePadding
              //    으로 content 만 밀어낸다. 상태바는 AnnotatedRegion 으로 투명 처리.
              NotificationListener<ScrollNotification>(
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
                  controller: _scrollController,
                  physics: SnapScrollPhysics(snapOffset: headerHeight),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 캐릭터 카드 + 상태 알약을 한 Stack 으로 묶어, 알약이
                          // 카드 안쪽 바닥 부근에 떠있는 모양으로 배치한다.
                          // (Transform.translate 로 끌어올리면 layout slot 이 그대로
                          // 남아 아래에 빈 공간이 생기므로 Stack 으로 처리.)
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              CharacterCard(
                                state: state,
                                character: character,
                                isCharacterLoading: isCharacterLoading,
                                hideCharacter: _evolving,
                                topSafePadding: topInset,
                                onTapShop: () =>
                                    context.push(AppRoutes.tamagochiShop),
                                onTapCollection: () => context
                                    .push(AppRoutes.tamagochiCollection),
                                onEggTap: _handleEggTap,
                                onCharacterTap: () {
                                  final remaining = todayTodos
                                      .where((t) => !t.isDone)
                                      .length;
                                  ref
                                      .read(tamagochiViewModelProvider
                                      .notifier)
                                      .onCharacterTap(
                                    remainingTodayTodos: remaining,
                                  );
                                },
                              ),
                              if (character != null && !character.isEgg)
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 8.h,
                                  child: StatusPill(
                                    character: character,
                                    streakDays: streak.currentCount,
                                    streakSlots: streakWindow.slots,
                                    isRewardClaimable:
                                    streak.hasCompletedBlock,
                                    isClaimingReward: _claimingReward,
                                    onClaimReward: _handleClaimReward,
                                    onTapEvolve: _handleEvolveTap,
                                    onTapFarewell: _handleFarewellTap,
                                    actionBusy: _evolving || _farewelling,
                                  ),
                                ),
                            ],
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
                              padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _CrossSectionTodoList(
                                    scrollController: _scrollController,
                                    todayTitle: '오늘의 할 일',
                                    todayTodos: todayTodos,
                                    somedayTodos: somedayTodos,
                                    showSomeday: true,
                                    onToggleToday: todoVm.toggleTodo,
                                    onToggleSomeday: todoVm.toggleSomedayTodo,
                                    onReorderToday: todoVm.reorderTodo,
                                    onReorderSomeday: todoVm.reorderSomedayTodo,
                                    onMoveToSomeday: todoVm.moveToSomeday,
                                    onMoveToToday: todoVm.moveToToday,
                                    onSnooze: todoVm.snoozeTodo,
                                    onAddToday: () => _openAddSheet(context, DateTime.now()),
                                    onAddSomeday: () => _openAddSheet(context, null),
                                    onTapToday: (todo) => _openDetailSheet(context, todo, false),
                                    onTapSomeday: (todo) => _openDetailSheet(context, todo, true),
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

              // 2. 헤더가 스크롤로 사라졌을 때만 뜨는 상태바 scrim.
              //    헤더가 보이는 동안은 완전 투명 — 캐릭터 카드의 grass 배경이
              //    그대로 상태바까지 이어져 보이게 한다. 스크롤되어 투두 리스트가
              //    상태바 위로 올라올 때만 scaffold 배경색으로 덮는다.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: topInset,
                child: _StatusBarScrim(visible: _headerVisible),
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
    case TodoDateType.someday:
      return false;

    case TodoDateType.range:
    // ✅ fetchTodos에서 시작일은 todo.date에 저장됨 (rangeStart는 null)
      final start = todo.date ?? todo.rangeStart;
      final end = todo.rangeEnd;
      if (start == null) return false;
      if (!onOrBefore(start, today)) return false;
      if (end == null) return true;
      return onOrBefore(today, end);

    case TodoDateType.repeat:
    // ✅ fetchTodos에서 시작일은 todo.date에 저장됨 (repeatStartDate는 null)
      final start = todo.date ?? todo.repeatStartDate;
      final end = todo.repeatEndDate;
      if (start == null) return false;
      if (!onOrBefore(start, today)) return false;
      if (end != null && today.isAfter(end)) return false;

      // ✅ 오늘이 반복 요일에 해당하는지 체크 (캘린더와 동일한 로직)
      if (todo.repeatDays != null && todo.repeatDays!.isNotEmpty) {
        final flutterWd = today.weekday; // 1=월~6=토, 7=일
        final appIndex  = flutterWd == 7 ? 0 : flutterWd; // 일요일(7)→0
        return todo.repeatDays!.contains(appIndex);
      } else {
        // repeatDays 없으면 시작 요일과 일치하는지 폴백
        return today.weekday == start.weekday;
      }
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

/// 스크롤되어 헤더(캐릭터 카드 + 스트릭) 가 사라졌을 때만 상태바 영역에 올라오는
/// scaffold 색 scrim. 헤더가 보이는 동안은 opacity 0 이라 투명하고, 그때는 캐릭터
/// 카드의 grass 배경이 상태바까지 그대로 이어져 보인다.
class _StatusBarScrim extends StatelessWidget {
  const _StatusBarScrim({required this.visible});

  /// 헤더가 "보이는" 상태인지. true 일수록 scrim 을 가린다 (투명).
  final ValueListenable<bool> visible;

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    return ValueListenableBuilder<bool>(
      valueListenable: visible,
      builder: (context, isVisible, _) {
        return AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isVisible ? 0.0 : 1.0,
          child: ColoredBox(color: bg),
        );
      },
    );
  }
}

// ✅ 오늘의 할 일 + 언젠가 할 일 섹션 간 드래그앤드롭 위젯
// 드래그 중 화면 상/하단 근접 시 부모 ScrollController로 자동 스크롤
class _CrossSectionTodoList extends ConsumerStatefulWidget {
  const _CrossSectionTodoList({
    required this.todayTitle,
    required this.todayTodos,
    required this.somedayTodos,
    required this.showSomeday,
    required this.onToggleToday,
    required this.onToggleSomeday,
    required this.onReorderToday,
    required this.onReorderSomeday,
    required this.onMoveToSomeday,
    required this.onMoveToToday,
    required this.onSnooze,
    required this.onAddToday,
    required this.onAddSomeday,
    required this.onTapToday,
    required this.onTapSomeday,
    this.scrollController,
  });

  final String todayTitle;
  final List<Todo> todayTodos;
  final List<Todo> somedayTodos;
  final bool showSomeday;
  final ValueChanged<String> onToggleToday;
  final ValueChanged<String> onToggleSomeday;
  final ReorderCallback onReorderToday;
  final ReorderCallback onReorderSomeday;
  final void Function(String id, {int targetIndex}) onMoveToSomeday;
  final void Function(String id, {int targetIndex}) onMoveToToday;
  final void Function(String id) onSnooze;
  final VoidCallback onAddToday;
  final VoidCallback onAddSomeday;
  final void Function(Todo) onTapToday;
  final void Function(Todo) onTapSomeday;
  final ScrollController? scrollController;

  @override
  ConsumerState<_CrossSectionTodoList> createState() => _CrossSectionTodoListState();
}

class _CrossSectionTodoListState extends ConsumerState<_CrossSectionTodoList> {
  Timer? _scrollTimer;
  static const double _scrollThreshold = 100.0; // 상/하단 임계치 px
  static const double _scrollSpeed = 8.0;        // 스크롤 속도 px/tick

  void _startAutoScroll(double pointerY, double screenHeight) {
    _scrollTimer?.cancel();
    final sc = widget.scrollController;
    if (sc == null || !sc.hasClients) return;

    _scrollTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!sc.hasClients) { _scrollTimer?.cancel(); return; }
      if (pointerY < _scrollThreshold) {
        // 상단 근접 → 위로 스크롤
        final target = (sc.offset - _scrollSpeed).clamp(0.0, sc.position.maxScrollExtent);
        sc.jumpTo(target);
      } else if (pointerY > screenHeight - _scrollThreshold) {
        // 하단 근접 → 아래로 스크롤
        final target = (sc.offset + _scrollSpeed).clamp(0.0, sc.position.maxScrollExtent);
        sc.jumpTo(target);
      } else {
        _scrollTimer?.cancel();
      }
    });
  }

  void _stopAutoScroll() {
    _scrollTimer?.cancel();
    _scrollTimer = null;
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final todayCount = widget.todayTodos.length;
    final dividerIndex = todayCount;
    final totalCount = widget.showSomeday
        ? todayCount + 1 + widget.somedayTodos.length
        : todayCount;

    void _resetReordering() {
      // ✅ ViewModel 전역 락 해제
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          ref.read(todoViewModelProvider.notifier).finishReorder();
        }
      });
    }

    void handleReorder(int oldIndex, int newIndex) {
      // ✅ ViewModel 전역 락: todo_page/tamagochi_page 중복 발화 방지
      final vm = ref.read(todoViewModelProvider.notifier);
      if (!vm.tryStartReorder()) return;

      if (!widget.showSomeday) {
        if (oldIndex < newIndex) newIndex -= 1;
        widget.onReorderToday(oldIndex, newIndex);
        _resetReordering();
        return;
      }

      // 헤더 자체는 드래그 불가
      if (oldIndex == dividerIndex) {
        vm.finishReorder();
        return;
      }

      // ✅ dividerIndex 특별 조정 제거 — standard adjustment만 적용
      // today[i] → dividerIndex 드롭: if(i < N) → newIndex=N-1, isToday=true (오늘 마지막) ✓
      // someday[j] → dividerIndex 드롭: if(j < N)=false → newIndex=N, isToday=false
      //   → !wasToday && !isToday && newIndex==dividerIndex → 오늘 마지막으로 이동 ✓
      if (oldIndex < newIndex) newIndex -= 1;

      final bool wasToday = oldIndex < dividerIndex;
      final bool isToday = newIndex < dividerIndex;

      if (wasToday && isToday) {
        // 오늘 섹션 내 재정렬
        widget.onReorderToday(oldIndex, newIndex);
      } else if (!wasToday && !isToday) {
        if (newIndex == dividerIndex) {
          // ✅ 언젠가 아이템을 divider에 드롭 → 오늘의 마지막 위치로 이동
          final somedayOld = oldIndex - dividerIndex - 1;
          widget.onMoveToToday(
            widget.somedayTodos[somedayOld].id,
            targetIndex: widget.todayTodos.length,
          );
        } else {
          // 언젠가 섹션 내 재정렬
          // ⚠️ same-section reorder 는 cross-section 과 달리 list 길이가 그대로라
          // somedayOld 와 동일하게 `-dividerIndex - 1` 로 변환해야 한다. 이전엔
          // `-dividerIndex` 로 변환하고 ViewModel 의 추가 `-1` 보정에 의존하던 구조였는데,
          // ViewModel 보정을 제거한 뒤로는 이 한 줄이 안 맞으면 RangeError 가 난다.
          final somedayOld = oldIndex - dividerIndex - 1;
          final somedayNew = newIndex - dividerIndex - 1;
          widget.onReorderSomeday(somedayOld, somedayNew);
        }
      } else if (wasToday && !isToday) {
        // ✅ 오늘 → 언젠가 이동
        final targetIdx = (newIndex - dividerIndex).clamp(0, widget.somedayTodos.length);
        widget.onMoveToSomeday(widget.todayTodos[oldIndex].id, targetIndex: targetIdx);
      } else {
        // ✅ 언젠가 → 오늘 이동
        final somedayOld = oldIndex - dividerIndex - 1;
        final targetIdx = newIndex.clamp(0, widget.todayTodos.length);
        widget.onMoveToToday(widget.somedayTodos[somedayOld].id, targetIndex: targetIdx);
      }
      _resetReordering();
    }

    Widget buildItem(BuildContext context, int index) {
      if (index < dividerIndex) {
        final todo = widget.todayTodos[index];
        return Padding(
          key: ValueKey('today_${todo.id}'),
          padding: const EdgeInsets.only(bottom: 12),
          child: SlidableTodoItemCard(
            todo: todo,
            index: index,
            onToggle: () => widget.onToggleToday(todo.id),
            onTap: () => widget.onTapToday(todo),
            onSnooze: !todo.isDone ? () => widget.onSnooze(todo.id) : null,
          ),
        );
      }
      if (index == dividerIndex) {
        return _SectionHeader(
          key: const ValueKey('someday_header'),
          title: '언젠가 할 일',
          actionLabel: '추가하기',
          onActionTap: widget.onAddSomeday,
        );
      }
      final somedayIndex = index - dividerIndex - 1;
      final todo = widget.somedayTodos[somedayIndex];
      return Padding(
        key: ValueKey('someday_${todo.id}'),
        padding: const EdgeInsets.only(bottom: 12),
        child: SlidableTodoItemCard(
          todo: todo,
          index: index,
          onToggle: () => widget.onToggleSomeday(todo.id),
          onTap: () => widget.onTapSomeday(todo),
          onSnooze: null,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.todayTitle,
                style: AppTextStyles.titleSmall.copyWith(color: colors.textPrimary)),
            GestureDetector(
              onTap: widget.onAddToday,
              behavior: HitTestBehavior.opaque,
              child: Text('추가하기',
                  style: AppTextStyles.labelMedium.copyWith(color: colors.textSecondary)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (totalCount == 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text('할 일을 추가해보세요!',
                  style: AppTextStyles.bodySmall.copyWith(color: colors.textHint)),
            ),
          )
        else
        // ✅ Listener로 드래그 중 포인터 위치 감지 → 자동 스크롤
          Listener(
            onPointerMove: (event) {
              final screenHeight = MediaQuery.of(context).size.height;
              _startAutoScroll(event.position.dy, screenHeight);
            },
            onPointerUp: (_) => _stopAutoScroll(),
            onPointerCancel: (_) => _stopAutoScroll(),
            child: ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: totalCount,
              onReorder: handleReorder,
              proxyDecorator: (child, index, animation) =>
                  Material(color: Colors.transparent, elevation: 0, child: child),
              itemBuilder: buildItem,
            ),
          ),
      ],
    );
  }
}

// 섹션 구분 헤더
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    super.key,
    required this.title,
    required this.actionLabel,
    required this.onActionTap,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onActionTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // ✅ 상단 패딩을 크게 해서 오늘 섹션 마지막 아이템과 헤더 사이
    // 드롭 감지 영역을 충분히 확보 (off-by-one 방지)
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: AppTextStyles.titleSmall.copyWith(color: colors.textPrimary)),
          GestureDetector(
            onTap: onActionTap,
            behavior: HitTestBehavior.opaque,
            child: Text(actionLabel,
                style: AppTextStyles.labelMedium.copyWith(color: colors.textSecondary)),
          ),
        ],
      ),
    );
  }
}