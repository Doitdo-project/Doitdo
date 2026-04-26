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
import 'package:doitdo/presentation/widgets/layouts/doitdo_scaffold.dart';
import 'package:doitdo/presentation/pages/todo/widgets/todo_add_sheet.dart';
import 'package:doitdo/presentation/pages/todo/widgets/todo_detail_sheet.dart';

class TodoPage extends ConsumerStatefulWidget {
  const TodoPage({super.key});

  @override
  ConsumerState<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends ConsumerState<TodoPage> {

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

    // ✅ 서버 카테고리 목록 구독 (실제 colorId 기반 색상 사용)
    final categoryList = ref.watch(categoryViewModelProvider).valueOrNull ?? [];

    // ✅ 카테고리 이름으로 실제 Color를 찾는 헬퍼
    Color getDotColor(String categoryName) {
      try {
        return categoryList.firstWhere((c) => c.categoryName == categoryName).color;
      } catch (_) {
        return AppColors.calendarPoint; // 매칭 없으면 기본 오렌지
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
                              onTap: () => _showFormatDropdown(context, state.calendarFormat),
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: colors.surface,
                                  borderRadius: BorderRadius.circular(8),
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
                        Row(
                          children: [
                            GestureDetector(
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
                      cellMargin: const EdgeInsets.all(10),
                    ),
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, day, events) {
                        if (events.isEmpty) return const SizedBox.shrink();
                        final todos = events.cast<Todo>().take(6).toList();
                        final row1 = todos.take(3).toList();
                        final row2 = todos.length > 3 ? todos.sublist(3) : <Todo>[];

                        // ✅ 하드코딩 _dotColor 대신 서버 카테고리 실제 색상 사용
                        Widget dotRow(List<Todo> items) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: items.map((t) => Container(
                            width: 5, height: 5, margin: const EdgeInsets.only(right: 2),
                            decoration: BoxDecoration(
                              color: getDotColor(t.category.name), // ✅ 이름으로 실제 색상 조회
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

          Padding(
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