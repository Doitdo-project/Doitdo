import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:doitdo/core/theme/app_colors.dart';
import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/models/todo.dart';
import 'package:doitdo/presentation/pages/todo/todo_view_model.dart';
import 'package:doitdo/presentation/widgets/common/todo_section.dart';
import 'package:doitdo/presentation/widgets/layouts/doitdo_scaffold.dart';
import 'package:doitdo/presentation/pages/todo/widgets/todo_add_sheet.dart';
import 'package:doitdo/presentation/pages/todo/widgets/todo_detail_sheet.dart';

class TodoPage extends ConsumerStatefulWidget {
  const TodoPage({super.key});

  @override
  ConsumerState<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends ConsumerState<TodoPage> {


  /// 캘린더 날짜 아래 점(marker) 색.
  /// 배경용 파스텔(category1~5) 은 점 크기(5x5) 에선 거의 안 보여서,
  /// 강조 팔레트(categoryDot1~5) 를 사용.
  static Color _dotColor(CategoryColorKey key) {
    switch (key) {
      case CategoryColorKey.study:    return AppColors.categoryDot1;
      case CategoryColorKey.exercise: return AppColors.categoryDot2;
      case CategoryColorKey.work:     return AppColors.categoryDot3;
      case CategoryColorKey.health:   return AppColors.categoryDot4;
      case CategoryColorKey.hobby:    return AppColors.categoryDot5;
      case CategoryColorKey.etc:      return AppColors.textLowIntensity;
    }
  }

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
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(0, 100, 200, 0),
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

    PopupMenuItem<String> buildItem(String value, String text) {
      final isSelected = value == currentFilter;
      return PopupMenuItem<String>(
        value: value,
        child: Text(text, style: AppTextStyles.bodyMedium.copyWith(
          color: isSelected ? AppColors.calendarPoint : colors.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        )),
      );
    }

    showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(1000, 100, 16, 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: colors.surface,
      items: [
        buildItem('all', '모든 할 일'),
        buildItem('todo', '미완료 (TODO)'),
        buildItem('done', '완료 (DONE)'),
        const PopupMenuDivider(),
        buildItem('upcoming', '예정된 할 일'),
        buildItem('past', '지난 할 일'),
      ],
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

  String _sectionTitle(String filter, DateTime? selectedDay) {
    switch (filter) {
      case 'upcoming': return '예정된 할 일';
      case 'past':     return '지난 할 일';
      case 'todo':     return '미완료된 할 일';
      case 'done':     return '완료된 할 일';
      default:         return '오늘의 할 일';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state  = ref.watch(todoViewModelProvider);
    final vm     = ref.read(todoViewModelProvider.notifier);
    final colors = context.colors;

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
              // 페이지 좌우 여백 24px — 홈/설정 탭과 통일 (가이드 §4 DoitdoPaddingLayout 기준).
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Padding(
                    // 헤더 왼쪽 여백(12) 은 아래 TableCalendar 의 요일('일') 컬럼과 라인을 맞추기 위함.
                    // 아래 여백(20) 은 "4월" 타이틀과 요일 헤더 사이에 숨 쉬는 공간 확보.
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
                              onTap: () => _showFormatDropdown(context, state.calendarFormat),
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: colors.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  // 시안: 테두리 없음 — 탭 가능 표시는 dropdown 아이콘으로 충분.
                                ),
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
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => _showFilterMenu(context, state.currentFilter),
                          behavior: HitTestBehavior.opaque,
                          child: Icon(Icons.filter_alt_outlined, size: 24, color: colors.textPrimary),
                        ),
                      ],
                    ),
                  ),

                  TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: state.focusedDay,
                    selectedDayPredicate: (day) => state.selectedDay != null && isSameDay(state.selectedDay, day),
                    calendarFormat: state.calendarFormat,
                    availableCalendarFormats: const {CalendarFormat.month: '월간', CalendarFormat.week: '주간'},
                    onDaySelected: vm.onDaySelected,
                    onFormatChanged: vm.onFormatChanged,
                    onPageChanged: (focusedDay) => vm.onDaySelected(focusedDay, focusedDay),
                    headerVisible: false,
                    locale: 'ko_KR',
                    eventLoader: (day) => state.allTodos.where((t) => t.date != null && isSameDay(t.date!, day)).toList(),
                    rowHeight: 52,
                    // 요일 헤더 ↔ 첫 날짜 행 간격을 날짜 행 간격(rowHeight 기반) 과 맞춤.
                    daysOfWeekHeight: 40,
                    daysOfWeekStyle: DaysOfWeekStyle(
                      dowTextFormatter: (date, locale) {
                        const days = ['일', '월', '화', '수', '목', '금', '토'];
                        return days[date.weekday % 7];
                      },
                      weekdayStyle: AppTextStyles.labelLarge.copyWith(color: colors.textSecondary),
                      weekendStyle: AppTextStyles.labelLarge.copyWith(color: colors.textSecondary),
                    ),
                    calendarStyle: CalendarStyle(
                      markersMaxCount: 0,
                      todayDecoration: const BoxDecoration(color: AppColors.homeCalendarSelectedBg, shape: BoxShape.circle),
                      todayTextStyle: AppTextStyles.labelMedium.copyWith(color: AppColors.calendarPoint),
                      selectedDecoration: const BoxDecoration(color: AppColors.calendarPoint, shape: BoxShape.circle),
                      selectedTextStyle: AppTextStyles.labelMedium.copyWith(color: Colors.white),
                      defaultTextStyle: AppTextStyles.labelMedium.copyWith(color: colors.textPrimary),
                      weekendTextStyle: AppTextStyles.labelMedium.copyWith(color: colors.textPrimary),
                      outsideTextStyle: AppTextStyles.labelMedium.copyWith(color: colors.textHint),
                      // cellMargin 을 넉넉히 줘서 원형 decoration 이 숫자를 감쌀 정도 크기로만 렌더.
                      // (0 이면 셀 전체를 덮어 과도하게 큰 원이 됨)
                      cellMargin: const EdgeInsets.all(10),
                    ),
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, day, events) {
                        if (events.isEmpty) return const SizedBox.shrink();
                        final todos = events.cast<Todo>().take(6).toList();
                        final row1 = todos.take(3).toList();
                        final row2 = todos.length > 3 ? todos.sublist(3) : <Todo>[];

                        Widget dotRow(List<Todo> items) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: items.map((t) => Container(
                            width: 5, height: 5, margin: const EdgeInsets.only(right: 2),
                            decoration: BoxDecoration(color: _dotColor(t.category.colorKey), shape: BoxShape.circle),
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

          Padding(
            // 마스코트 말풍선 위아래로 숨 쉬는 공간 — 캘린더/할 일 섹션과 시각적 분리.
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset('assets/images/Dooit.png', width: 26, height: 26),
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
          // 할 일 섹션
          // ══════════════════════════════════════
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TodoSection(
                    title: _sectionTitle(state.currentFilter, state.selectedDay),
                    todos: state.todos,
                    onToggle: vm.toggleTodo,
                    onReorder: vm.reorderTodo,
                    onSnooze: vm.snoozeTodo,
                    actionLabel: '추가하기',
                    onActionTap: () => _openAddSheet(context, state.selectedDay ?? DateTime.now()),
                    onTodoTap: (todo) => _openDetailSheet(context, todo, false),
                  ),
                  const SizedBox(height: 24),

                  TodoSection(
                    title: '언제가 할 일',
                    todos: state.somedayTodos,
                    onToggle: vm.toggleSomedayTodo,
                    onReorder: vm.reorderSomedayTodo,
                    onSnooze: null,
                    actionLabel: '추가하기',
                    onActionTap: () => _openAddSheet(context, null),
                    onTodoTap: (todo) => _openDetailSheet(context, todo, true),
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

