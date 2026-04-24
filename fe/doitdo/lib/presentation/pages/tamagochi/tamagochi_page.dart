import 'package:doitdo/core/utils/snap_scroll_physics.dart';
import 'package:doitdo/domain/entities/character.dart';
import 'package:doitdo/presentation/models/todo.dart';
import 'package:doitdo/presentation/navigation/app_router.dart';
import 'package:doitdo/presentation/pages/tamagochi/character_view_model.dart';
import 'package:doitdo/presentation/pages/tamagochi/tamagochi_view_model.dart';
import 'package:doitdo/presentation/pages/tamagochi/widgets/character_card.dart';
import 'package:doitdo/presentation/pages/tamagochi/widgets/farewell_banner.dart';
import 'package:doitdo/presentation/pages/tamagochi/widgets/streak_section.dart';
import 'package:doitdo/presentation/pages/todo/todo_state.dart';
import 'package:doitdo/presentation/pages/todo/todo_view_model.dart';
import 'package:doitdo/presentation/pages/todo/widgets/todo_add_sheet.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_dialog.dart';
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

  /// farewell API 호출 in-flight 여부. 버튼 중복 탭 방지용.
  bool _farewelling = false;

  @override
  void initState() {
    super.initState();
    // 진입 시 캐릭터 조회 + 미수령이면 자동 POST. 로그인 플로우에서는 이쪽만
    // 돌리고 welcome_page 에서는 띄우지 않아, 두 경로 load() 가 경쟁하다
    // "GET 실패 → POST" 판정이 덮이는 상황을 막는다.
    //
    // TodoViewModel 은 생성자에서 fetchTodos() 를 자동 호출하므로 홈에서
    // 별도 부트스트랩은 불필요 — build 안 ref.watch 만으로 초기 로드됨.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(characterViewModelProvider.notifier).ensureCharacter();
    });
  }

  @override
  void dispose() {
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
  Future<void> _refreshCharacterAfterTodoDone() async {
    final vm = ref.read(characterViewModelProvider.notifier);
    final beforeExp =
        ref.read(characterViewModelProvider).valueOrNull?.currentExp;

    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    await vm.refresh();
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
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (_) => TodoAddSheet(initialDate: date),
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

  /// 독립 시키기 버튼 탭. 확인 다이얼로그로 한 번 감싼 뒤 farewell API 호출.
  /// 성공 시 서버가 다음 알을 자동 배정하므로 ViewModel 이 load() 로 갱신.
  Future<void> _handleFarewellTap() async {
    if (_farewelling) return;
    final confirmed = await showDoitdoDialog(
      context: context,
      title: '독립 시키기',
      message: '지금까지 함께한 다마고치를 배웅할게요.\n'
          '독립하면 되돌릴 수 없고 바로 새 알이 도착해요.',
      confirmLabel: '독립 시키기',
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

    // 에러 스낵바 + canEvolve 에지 자동 진화 트리거. 두 작업 모두 character 상태
    // 변화에 반응하므로 같은 ref.listen 에 묶는다. canEvolve 는 BABY/TEEN 에서만
    // true 가 되고 ADULT 는 canFarewell 로 전환되므로 stage 검사는 생략. 재렌더
    // 시 중복 호출되지 않도록 "false→true" 순간에만 호출한다.
    ref.listen<AsyncValue<Character?>>(characterViewModelProvider,
        (prev, next) {
      next.whenOrNull(error: (err, _) {
        if (!mounted) return;
        _showComingSoon(context, '캐릭터 정보를 불러오지 못했어요. 잠시 후 다시 시도해주세요.');
      });

      final prevChar = prev?.valueOrNull;
      final nextChar = next.valueOrNull;
      if (nextChar == null || !nextChar.canEvolve) return;
      final wasAlreadyEvolvable = prevChar != null && prevChar.canEvolve;
      if (wasAlreadyEvolvable) return;
      ref
          .read(characterViewModelProvider.notifier)
          .evolve(nextChar.userCharacterId);
    });

    // Todo 완료 count 가 증가하면 exp 가 올라갔을 가능성이 있으므로 캐릭터 재조회.
    // BE 는 AFTER_COMMIT 리스너로 exp 를 비동기 부여하므로 곧장 GET /me 를 부르면
    // 옛 값을 받을 수 있다. 200ms 먼저 조회해보고 exp 변화가 없으면 500ms 뒤 한 번 더.
    ref.listen<TodoState>(todoViewModelProvider, (prev, next) {
      if (prev == null) return;
      final prevDone = _doneCount(prev);
      final nextDone = _doneCount(next);
      if (nextDone > prevDone) {
        _refreshCharacterAfterTodoDone();
      }
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
                              topSafePadding: topInset,
                              onTapShop: () => _showComingSoon(
                                context,
                                '상점 기능은 아직 준비 중이에요.',
                              ),
                              onTapCollection: () =>
                                  context.push(AppRoutes.tamagochiCollection),
                              onEggTap: _handleEggTap,
                            ),
                            if (character?.canFarewell ?? false) ...[
                              SizedBox(height: 12.h),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.w),
                                child: FarewellBanner(
                                  characterName: character!.name,
                                  busy: _farewelling,
                                  onTap: _handleFarewellTap,
                                ),
                              ),
                            ],
                            SizedBox(height: _streakTopGap),
                            StreakSection(
                              streakDays: state.streakDays,
                              slots: state.streakSlots,
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
                                      onActionTap: () => _openAddSheet(
                                        context,
                                        DateTime.now(),
                                      ),
                                      todos: todayTodos,
                                      onToggle: todoVm.toggleTodo,
                                    ),
                                    const SizedBox(height: 24),
                                    TodoSection(
                                      title: '언젠가 할 일',
                                      actionLabel: '추가하기',
                                      onActionTap: () =>
                                          _openAddSheet(context, null),
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

/// TodoState 의 완료된 할 일 총 개수 (오늘의 할 일 + 언젠가 할 일).
int _doneCount(TodoState s) =>
    s.allTodos.where((t) => t.isDone).length +
    s.allSomedayTodos.where((t) => t.isDone).length;

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
