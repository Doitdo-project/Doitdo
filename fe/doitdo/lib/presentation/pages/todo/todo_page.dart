import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:doitdo/core/theme/app_colors.dart';
import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/pages/todo/todo_view_model.dart';
import 'package:doitdo/presentation/widgets/common/todo_section.dart';
import 'package:doitdo/presentation/widgets/layouts/doitdo_scaffold.dart';
import 'package:doitdo/presentation/pages/todo/widgets/todo_add_sheet.dart';

class TodoPage extends ConsumerStatefulWidget {
  const TodoPage({super.key});

  @override
  ConsumerState<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends ConsumerState<TodoPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
            () => ref.read(todoViewModelProvider.notifier).loadDummyTodos());
  }

  // ── 캘린더 스와이프 → 월간 / 주간 전환 ────────────────
  // 위로 스와이프(velocity < 0) → 주간
  // 아래로 스와이프(velocity > 0) → 월간
  // 우측 상단 '월간 ∨' 드롭다운과 동일한 동작
  void _onCalendarSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 300) return; // 느린 드래그 무시

    final format = ref.read(todoViewModelProvider).calendarFormat;
    final vm = ref.read(todoViewModelProvider.notifier);

    if (velocity < 0 && format != CalendarFormat.week) {
      vm.onFormatChanged(CalendarFormat.week);
    } else if (velocity > 0 && format != CalendarFormat.month) {
      vm.onFormatChanged(CalendarFormat.month);
    }
  }

  void _showFormatDropdown(BuildContext context, CalendarFormat current) {
    final vm = ref.read(todoViewModelProvider.notifier);
    final colors = context.colors;

    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(1000, 100, 16, 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: colors.surface,
      items: [
        PopupMenuItem(
          value: CalendarFormat.month,
          child: Text('월간',
              style: AppTextStyles.bodyMedium.copyWith(
                color: current == CalendarFormat.month
                    ? AppColors.calendarPoint
                    : colors.textPrimary,
              )),
        ),
        PopupMenuItem(
          value: CalendarFormat.week,
          child: Text('주간',
              style: AppTextStyles.bodyMedium.copyWith(
                color: current == CalendarFormat.week
                    ? AppColors.calendarPoint
                    : colors.textPrimary,
              )),
        ),
      ],
    ).then((value) {
      if (value != null) {
        ref.read(todoViewModelProvider.notifier).onFormatChanged(value);
      }
    });
  }

  void _openAddSheet(BuildContext context, DateTime? date) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (_) => TodoAddSheet(initialDate: date ?? DateTime.now()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(todoViewModelProvider);
    final vm = ref.read(todoViewModelProvider.notifier);
    final colors = context.colors;

    return DoitdoScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          // ══════════════════════════════════════════
          // 캘린더 영역
          //   - 스와이프 제스처로 월간 ↔ 주간 전환
          //   - 이 영역은 스크롤과 무관하게 고정
          // ══════════════════════════════════════════
          GestureDetector(
            // 수직 스와이프 감지 (TableCalendar의 수평 스와이프와 충돌 없음)
            onVerticalDragEnd: _onCalendarSwipe,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // 헤더 (월 + 월간/주간 드롭다운)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${state.focusedDay.month}월',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _showFormatDropdown(
                              context, state.calendarFormat),
                          child: Row(
                            children: [
                              Text(
                                state.calendarFormat == CalendarFormat.month
                                    ? '월간'
                                    : '주간',
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: colors.textPrimary),
                              ),
                              const SizedBox(width: 2),
                              Icon(Icons.keyboard_arrow_down,
                                  size: 16, color: colors.textPrimary),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 달력
                  TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: state.focusedDay,
                    selectedDayPredicate: (day) =>
                    state.selectedDay != null &&
                        isSameDay(state.selectedDay, day),
                    calendarFormat: state.calendarFormat,
                    availableCalendarFormats: const {
                      CalendarFormat.month: '월간',
                      CalendarFormat.week: '주간',
                    },
                    onDaySelected: vm.onDaySelected,
                    onFormatChanged: vm.onFormatChanged,
                    onPageChanged: (focusedDay) =>
                        vm.onDaySelected(focusedDay, focusedDay),
                    headerVisible: false,
                    locale: 'ko_KR',
                    daysOfWeekStyle: DaysOfWeekStyle(
                      dowTextFormatter: (date, locale) {
                        const days = ['일', '월', '화', '수', '목', '금', '토'];
                        return days[date.weekday % 7];
                      },
                      weekdayStyle: AppTextStyles.labelLarge
                          .copyWith(color: colors.textSecondary),
                      weekendStyle: AppTextStyles.labelLarge
                          .copyWith(color: colors.textSecondary),
                    ),
                    calendarStyle: CalendarStyle(
                      todayDecoration: const BoxDecoration(
                        color: AppColors.homeCalendarSelectedBg,
                        shape: BoxShape.circle,
                      ),
                      todayTextStyle: AppTextStyles.labelMedium
                          .copyWith(color: AppColors.calendarPoint),
                      selectedDecoration: const BoxDecoration(
                        color: AppColors.calendarPoint,
                        shape: BoxShape.circle,
                      ),
                      selectedTextStyle: AppTextStyles.labelMedium
                          .copyWith(color: Colors.white),
                      defaultTextStyle: AppTextStyles.labelMedium
                          .copyWith(color: colors.textPrimary),
                      weekendTextStyle: AppTextStyles.labelMedium
                          .copyWith(color: colors.textPrimary),
                      outsideTextStyle: AppTextStyles.labelMedium
                          .copyWith(color: colors.textHint),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ══════════════════════════════════════════
          // 마스코트 말풍선 (캘린더 바로 아래 고정)
          // ══════════════════════════════════════════
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.calendar_month,
                    color: AppColors.calendarPoint, size: 28),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.bubbleBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '오늘도 차곡차곡 해내고 있구나!',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.calendarDateText),
                  ),
                ),
              ],
            ),
          ),

          // ══════════════════════════════════════════
          // 할 일 섹션 — 독립 스크롤 영역
          //   월간/주간 모두 자연스럽게 스크롤
          // ══════════════════════════════════════════
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 오늘의 할 일 (선택 날짜 기준, 제목 고정)
                  TodoSection(
                    title: '오늘의 할 일',
                    todos: state.todos,
                    onToggle: vm.toggleTodo,
                    actionLabel: '추가하기',
                    onActionTap: () =>
                        _openAddSheet(context, state.selectedDay),
                  ),
                  const SizedBox(height: 16),

                  // 언제가 할 일 (날짜 무관, 항상 동일)
                  TodoSection(
                    title: '언제가 할 일',
                    todos: state.somedayTodos,
                    onToggle: vm.toggleSomedayTodo,
                    actionLabel: '추가하기',
                    onActionTap: () => _openAddSheet(context, null),
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