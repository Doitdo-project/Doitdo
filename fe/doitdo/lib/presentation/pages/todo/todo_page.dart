import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:doitdo/core/theme/app_colors.dart';
import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/models/todo.dart';
import 'package:doitdo/presentation/navigation/app_router.dart';
import 'package:doitdo/presentation/pages/notification/notification_view_model.dart';
import 'package:doitdo/presentation/pages/setting/category/category_view_model.dart'; // ✅ 추가
import 'package:doitdo/presentation/pages/todo/todo_view_model.dart';
import 'package:doitdo/presentation/widgets/common/todo_section.dart';
import 'package:doitdo/presentation/widgets/common/todo_item_card.dart';
import 'package:doitdo/presentation/widgets/layouts/doitdo_scaffold.dart';
import 'package:doitdo/presentation/pages/todo/widgets/todo_add_sheet.dart';
import 'package:doitdo/presentation/pages/todo/widgets/todo_detail_sheet.dart';

class TodoPage extends ConsumerStatefulWidget {
  const TodoPage({super.key});

  @override
  ConsumerState<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends ConsumerState<TodoPage> {
  final _formatBtnKey = GlobalKey();
  final _filterBtnKey = GlobalKey();

  // ✅ _dotColor 하드코딩 메서드 삭제 — 서버 카테고리 색상으로 대체

  void _onCalendarSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 300) return;
    final format = ref.read(todoViewModelProvider).calendarFormat;
    final vm     = ref.read(todoViewModelProvider.notifier);
    if (velocity < 0 && format != CalendarFormat.week) {
      vm.onFormatChanged(CalendarFormat.week);
    } else if (velocity > 0 && format != CalendarFormat.month) {
      vm.onFormatChanged(CalendarFormat.month);
    }
  }

  void _showFormatDropdown(BuildContext context, CalendarFormat current) {
    final colors = context.colors;
    final renderBox = _formatBtnKey.currentContext?.findRenderObject() as RenderBox?;
    final RelativeRect position;
    if (renderBox != null) {
      final offset = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;
      position = RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + size.height + 4,
        screenWidth - offset.dx - size.width,
        screenHeight - offset.dy - size.height,
      );
    } else {
      position = const RelativeRect.fromLTRB(24, 100, 200, 0);
    }
    showMenu(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: colors.surface,
      items: [
        PopupMenuItem(
          value: CalendarFormat.month,
          child: Text('월간', style: AppTextStyles.bodyMedium.copyWith(
              color: current == CalendarFormat.month ? AppColors.calendarPoint : colors.textPrimary)),
        ),
        PopupMenuItem(
          value: CalendarFormat.week,
          child: Text('주간', style: AppTextStyles.bodyMedium.copyWith(
              color: current == CalendarFormat.week ? AppColors.calendarPoint : colors.textPrimary)),
        ),
      ],
    ).then((value) {
      if (value != null) ref.read(todoViewModelProvider.notifier).onFormatChanged(value);
    });
  }

  void _showFilterMenu(BuildContext context, String currentFilter) {
    final colors = context.colors;
    final vm = ref.read(todoViewModelProvider.notifier);
    final categories = ref.read(categoryViewModelProvider).valueOrNull ?? [];

    // 카테고리 필터 드롭다운
    final items = <PopupMenuEntry<String>>[
      PopupMenuItem<String>(
        value: 'all',
        child: Row(
          children: [
            Icon(
              Icons.list_outlined,
              size: 16,
              color: currentFilter == 'all'
                  ? AppColors.calendarPoint
                  : colors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              '전체',
              style: AppTextStyles.bodyMedium.copyWith(
                color: currentFilter == 'all'
                    ? AppColors.calendarPoint
                    : colors.textPrimary,
                fontWeight: currentFilter == 'all'
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      if (categories.isNotEmpty) const PopupMenuDivider(),
      ...categories.map((cat) {
        final value = 'cat:${cat.categoryName}';
        final isSelected = currentFilter == value;
        return PopupMenuItem<String>(
          value: value,
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: cat.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                cat.categoryName,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isSelected
                      ? AppColors.calendarPoint
                      : colors.textPrimary,
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }),
    ];

    final filterRenderBox = _filterBtnKey.currentContext?.findRenderObject() as RenderBox?;
    final RelativeRect filterPosition;
    if (filterRenderBox != null) {
      final offset = filterRenderBox.localToGlobal(Offset.zero);
      final size = filterRenderBox.size;
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;
      filterPosition = RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + size.height + 4,
        screenWidth - offset.dx - size.width,
        screenHeight - offset.dy - size.height,
      );
    } else {
      filterPosition = const RelativeRect.fromLTRB(1000, 55, 90, 0);
    }

    showMenu<String>(
      context: context,
      position: filterPosition,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: colors.surface,
      items: items,
    ).then((value) {
      if (value != null) vm.setFilter(value);
    });
  }

  void _openAddSheet(BuildContext context, DateTime? date) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent, useRootNavigator: true,
      builder: (_) => TodoAddSheet(initialDate: date),
    );
  }

  void _openDetailSheet(BuildContext context, Todo todo, bool isSomeday) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent, useRootNavigator: true,
      builder: (_) => TodoDetailSheet(todoId: todo.id, isSomeday: isSomeday),
    );
  }

  String _sectionTitle(String filter) {
    if (filter.startsWith('cat:')) return '${filter.substring(4)} 카테고리';
    return '오늘의 할 일';
  }

  @override
  Widget build(BuildContext context) {
    final state  = ref.watch(todoViewModelProvider);
    final vm     = ref.read(todoViewModelProvider.notifier);
    final colors = context.colors;

    // ✅ 서버 카테고리 목록 구독 (실제 colorId 기반 색상 사용)
    final categoryList = ref.watch(categoryViewModelProvider).valueOrNull ?? [];

    // ✅ 카테고리 이름으로 실제 Color를 찾는 헬퍼
    Color getDotColor(String categoryName) {
      try {
        return categoryList.firstWhere((c) => c.categoryName == categoryName).color;
      } catch (_) {
        return AppColors.category1; // detail sheet와 동일한 fallback
      }
    }

    final now = DateTime.now();
    final isToday = state.selectedDay != null &&
        state.selectedDay!.year == now.year &&
        state.selectedDay!.month == now.month &&
        state.selectedDay!.day == now.day;

    return DoitdoScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ══════════════════════════════════════
          // 캘린더 헤더 및 달력
          // ══════════════════════════════════════
          GestureDetector(
            onVerticalDragEnd: _onCalendarSwipe,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 12, bottom: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text('${state.focusedDay.month}월',
                                style: AppTextStyles.titleMedium.copyWith(color: colors.textPrimary)),
                            const SizedBox(width: 12),
                            GestureDetector(
                              key: _formatBtnKey,
                              onTap: () => _showFormatDropdown(context, state.calendarFormat),
                              behavior: HitTestBehavior.opaque,
                              child: Row(
                                children: [
                                  Text(
                                    state.calendarFormat == CalendarFormat.month ? '월간' : '주간',
                                    style: AppTextStyles.labelMedium.copyWith(color: colors.textSecondary),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.keyboard_arrow_down, size: 16, color: colors.textSecondary),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              key: _filterBtnKey,
                              onTap: () => _showFilterMenu(context, state.currentFilter),
                              behavior: HitTestBehavior.opaque,
                              child: Icon(Icons.filter_alt_outlined, size: 24, color: colors.textPrimary),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () => context.push(AppRoutes.notifications),
                              behavior: HitTestBehavior.opaque,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Icon(Icons.notifications_outlined, size: 24, color: colors.textPrimary),
                                  Consumer(
                                    builder: (context, ref, _) {
                                      final unread = ref.watch(
                                        notificationViewModelProvider.select((s) => s.unreadCount),
                                      );
                                      if (unread == 0) return const SizedBox.shrink();
                                      return Positioned(
                                        top: -4,
                                        right: -4,
                                        child: Container(
                                          width: 14,
                                          height: 14,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFE2782B),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              unread > 9 ? '9+' : '$unread',
                                              style: const TextStyle(
                                                fontSize: 8,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                                fontFamily: 'GmarketSansMedium',
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  TableCalendar(
                    // ✅ 카테고리 목록이 로드되면 마커를 강제로 다시 렌더링
                    key: ValueKey(categoryList.map((c) => '${c.categoryName}:${c.color.value}').join()),
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: state.focusedDay,
                    selectedDayPredicate: (day) => state.selectedDay != null && isSameDay(state.selectedDay, day),
                    calendarFormat: state.calendarFormat,
                    availableCalendarFormats: const {CalendarFormat.month: '월간', CalendarFormat.week: '주간'},
                    onDaySelected: vm.onDaySelected,
                    onFormatChanged: vm.onFormatChanged,
                    onPageChanged: (focusedDay) async {
                      // ✅ 달 이동 시 onDaySelected 내부에서 fetchCalendarData 자동 호출
                      await vm.onDaySelected(focusedDay, focusedDay);
                    },
                    headerVisible: false,
                    locale: 'ko_KR',
                    eventLoader: (day) {
                      final normalizedDay = DateTime(day.year, day.month, day.day);
                      return state.kEvents[normalizedDay] ?? [];
                    },
                    rowHeight: 52,
                    daysOfWeekHeight: 40,
                    daysOfWeekStyle: DaysOfWeekStyle(
                      dowTextFormatter: (date, locale) {
                        const days = ['일', '월', '화', '수', '목', '금', '토'];
                        return days[date.weekday % 7];
                      },
                      weekdayStyle: AppTextStyles.labelLarge.copyWith(color: colors.textSecondary),
                      // ✅ 요일 헤더: 일요일=빨강, 토요일=파랑
                      // weekendStyle은 토/일 동일 색상만 가능 → defaultBuilder로 구분
                      weekendStyle: AppTextStyles.labelLarge.copyWith(color: colors.textSecondary),
                    ),
                    calendarStyle: CalendarStyle(
                      markersMaxCount: 0,
                      todayDecoration: BoxDecoration(color: colors.calendarRangeHighlight, shape: BoxShape.circle),
                      todayTextStyle: AppTextStyles.labelMedium.copyWith(color: AppColors.calendarPoint),
                      selectedDecoration: const BoxDecoration(color: AppColors.calendarPoint, shape: BoxShape.circle),
                      selectedTextStyle: AppTextStyles.labelMedium.copyWith(color: Colors.white),
                      defaultTextStyle: AppTextStyles.labelMedium.copyWith(color: colors.textPrimary),
                      weekendTextStyle: AppTextStyles.labelMedium.copyWith(color: colors.textPrimary), // defaultBuilder가 우선 적용
                      outsideTextStyle: AppTextStyles.labelMedium.copyWith(color: Colors.transparent),
                      outsideDaysVisible: false,
                      cellMargin: const EdgeInsets.all(10),
                    ),
                    calendarBuilders: CalendarBuilders(
                      // ✅ 날짜 숫자: 일요일=빨강, 토요일=파랑 / 요일 헤더는 모두 검정
                      defaultBuilder: (context, day, focusedDay) {
                        Color? textColor;
                        if (day.weekday == DateTime.sunday) {
                          textColor = Colors.red;
                        } else if (day.weekday == DateTime.saturday) {
                          textColor = Colors.blue;
                        }
                        if (textColor == null) return null;
                        return Center(
                          child: Text(
                            '${day.day}',
                            style: AppTextStyles.labelMedium.copyWith(color: textColor),
                          ),
                        );
                      },
                      markerBuilder: (context, day, events) {
                        if (events.isEmpty) return const SizedBox.shrink();
                        var todos = events.cast<Todo>().toList();

                        // ✅ 현재 포커스된 달이 아닌 날짜(이전/다음 달)는 DOT도 흐리게
                        final isOutside = day.month != state.focusedDay.month;

                        // ✅ 3. 카테고리 필터 적용 시 DOT도 동일하게 필터링
                        final currentFilter = state.currentFilter;
                        if (currentFilter.startsWith('cat:')) {
                          final catName = currentFilter.substring(4);
                          todos = todos.where((t) => t.category.name == catName).toList();
                        }
                        if (todos.isEmpty) return const SizedBox.shrink();

                        // ✅ 2. 카테고리별로 DOT 중복 제거 (같은 카테고리는 1개만)
                        final seen = <String>{};
                        final uniqueTodos = todos.where((t) {
                          final name = t.category.name;
                          if (seen.contains(name)) return false;
                          seen.add(name);
                          return true;
                        }).take(6).toList();

                        final row1 = uniqueTodos.take(3).toList();
                        final row2 = uniqueTodos.length > 3 ? uniqueTodos.sublist(3) : <Todo>[];

                        // 1. 가장 추천하는 정교한 방법 (좌우 균등 마진)
                        Widget dotRow(List<Todo> items) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: items.map((t) => Container(
                            width: 5,
                            height: 5,
                            // 좌우로 1픽셀씩 마진을 줍니다. (점 사이 간격은 여전히 2픽셀이 됩니다)
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: getDotColor(t.category.name)
                                  .withOpacity(isOutside ? 0.3 : 1.0),
                              shape: BoxShape.circle,
                            ),
                          )).toList(),
                        );

                        return Positioned(
                          bottom: 3, left: 0, right: 0,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                dotRow(row1),
                                if (row2.isNotEmpty) ...[const SizedBox(height: 2), dotRow(row2)],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── 핸들바: 탭/스와이프로 월간↔주간 전환 ──
          GestureDetector(
            onVerticalDragEnd: _onCalendarSwipe,
            onTap: () {
              final isMonth = state.calendarFormat == CalendarFormat.month;
              vm.onFormatChanged(isMonth ? CalendarFormat.week : CalendarFormat.month);
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset('assets/images/Dooit.png', width: 26, height: 26, filterQuality: FilterQuality.high),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.bubbleBg,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12), topRight: Radius.circular(12),
                      bottomLeft: Radius.circular(4), bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Text('오늘도 차곡차곡 해내고 있구나!', style: AppTextStyles.bodySmall.copyWith(color: AppColors.calendarDateText)),
                ),
              ],
            ),
          ),

          // ══════════════════════════════════════
          // 할 일 섹션 (캘린더 고정 후 나머지 영역 스크롤)
          // ══════════════════════════════════════
          Expanded(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ✅ 오늘의 할 일 + 언젠가 할 일을 단일 ReorderableListView로 합침
                  // 섹션 경계(todayCount)를 넘으면 moveToSomeday/moveToToday 호출
                  _CrossSectionTodoList(
                    todayTitle: _sectionTitle(state.currentFilter),
                    todayTodos: state.todos,
                    somedayTodos: state.currentFilter == 'all' || !state.currentFilter.startsWith('cat:')
                        ? state.somedayTodos
                        : [],
                    showSomeday: state.currentFilter == 'all' || !state.currentFilter.startsWith('cat:'),
                    onToggleToday: vm.toggleTodo,
                    onToggleSomeday: vm.toggleSomedayTodo,
                    onReorderToday: vm.reorderTodo,
                    onReorderSomeday: vm.reorderSomedayTodo,
                    onMoveToSomeday: vm.moveToSomeday,
                    onMoveToToday: vm.moveToToday,
                    onSnooze: vm.snoozeTodo,
                    onAddToday: () => _openAddSheet(context, state.selectedDay ?? DateTime.now()),
                    onAddSomeday: () => _openAddSheet(context, null),
                    onTapToday: (todo) => _openDetailSheet(context, todo, false),
                    onTapSomeday: (todo) => _openDetailSheet(context, todo, true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ 오늘의 할 일 + 언젠가 할 일 섹션 간 드래그앤드롭 위젯
// 두 섹션 헤더를 유지하면서 경계를 넘어 드래그 가능
class _CrossSectionTodoList extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final todayCount = todayTodos.length;
    // 합친 리스트 구조:
    // index 0..todayCount-1       → 오늘의 할 일 아이템
    // index todayCount            → 언젠가 할 일 헤더 (드래그 불가)
    // index todayCount+1..end     → 언젠가 할 일 아이템
    // showSomeday=false면 오늘 아이템만

    final int dividerIndex = todayCount; // 헤더 위치
    final int totalCount = showSomeday
        ? todayCount + 1 + somedayTodos.length  // 헤더 포함
        : todayCount;

    void handleReorder(int oldIndex, int newIndex) {
      if (!showSomeday) {
        if (oldIndex < newIndex) newIndex -= 1;
        onReorderToday(oldIndex, newIndex);
        return;
      }

      // 헤더(dividerIndex)를 드래그하면 무시
      if (oldIndex == dividerIndex) return;

      // newIndex가 헤더 위치면 인접 위치로 보정
      if (newIndex == dividerIndex) newIndex += 1;

      if (oldIndex < newIndex) newIndex -= 1;

      final bool wasToday = oldIndex < dividerIndex;
      // dividerIndex 기준으로 실제 섹션 경계
      // newIndex는 헤더 제거 후 기준으로 판단
      final bool isToday = newIndex < dividerIndex;

      if (wasToday && isToday) {
        // 오늘 섹션 내 재정렬
        onReorderToday(oldIndex, newIndex);
      } else if (!wasToday && !isToday) {
        // 언젠가 섹션 내 재정렬 (헤더 offset 제거)
        final somedayOld = oldIndex - dividerIndex - 1;
        final somedayNew = newIndex - dividerIndex;
        onReorderSomeday(somedayOld, somedayNew);
      } else if (wasToday && !isToday) {
        // ✅ 오늘 → 언젠가로 이동
        // ✅ 오늘 item 제거로 divider가 1칸 앞으로 당겨지므로 -dividerIndex만 적용
        final targetIdx = newIndex > dividerIndex - 1
            ? newIndex - dividerIndex  // = newIndex - (dividerIndex - 1) - 1
            : 0;
        onMoveToSomeday(todayTodos[oldIndex].id, targetIndex: targetIdx);
      } else {
        // ✅ 언젠가 → 오늘로 이동
        final somedayOld = oldIndex - dividerIndex - 1;
        // ✅ someday item 제거해도 today 인덱스는 불변
        final targetIdx = newIndex < dividerIndex ? newIndex : dividerIndex - 1;
        onMoveToToday(somedayTodos[somedayOld].id, targetIndex: targetIdx);
      }
    }

    Widget buildItem(BuildContext context, int index) {
      // 오늘의 할 일 아이템
      if (index < dividerIndex) {
        final todo = todayTodos[index];
        return Padding(
          key: ValueKey('today_${todo.id}'),
          padding: const EdgeInsets.only(bottom: 12),
          child: SlidableTodoItemCard(
            todo: todo,
            index: index,
            onToggle: () => onToggleToday(todo.id),
            onTap: () => onTapToday(todo),
            onSnooze: !todo.isDone ? () => onSnooze(todo.id) : null,
          ),
        );
      }

      // 언젠가 할 일 헤더 (드래그 불가 — ReorderableDragStartListener 미적용)
      if (index == dividerIndex) {
        return _SectionHeader(
          key: const ValueKey('someday_header'),
          title: '언젠가 할 일',
          actionLabel: '추가하기',
          onActionTap: onAddSomeday,
        );
      }

      // 언젠가 할 일 아이템
      final somedayIndex = index - dividerIndex - 1;
      final todo = somedayTodos[somedayIndex];
      return Padding(
        key: ValueKey('someday_${todo.id}'),
        padding: const EdgeInsets.only(bottom: 12),
        child: SlidableTodoItemCard(
          todo: todo,
          index: index,
          onToggle: () => onToggleSomeday(todo.id),
          onTap: () => onTapSomeday(todo),
          onSnooze: null,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 오늘의 할 일 헤더 (리스트 밖)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(todayTitle,
                style: AppTextStyles.titleSmall.copyWith(color: colors.textPrimary)),
            GestureDetector(
              onTap: onAddToday,
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
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalCount,
            onReorder: handleReorder,
            proxyDecorator: (child, index, animation) =>
                Material(color: Colors.transparent, elevation: 0, child: child),
            itemBuilder: buildItem,
          ),
      ],
    );
  }
}

// 섹션 구분 헤더 (드래그 핸들 없음)
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
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 12),
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