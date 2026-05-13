import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:doitdo/core/theme/app_colors.dart';
import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/models/todo.dart'; // ✏️ 추가: TodoDateType 이 todo.dart 로 이동됨
import 'package:doitdo/presentation/widgets/common/doitdo_primary_button.dart';
import 'package:doitdo/presentation/widgets/common/character_mascot_image.dart';

// ─────────────────────────────────────────────
// 날짜 선택 결과 모델
// ─────────────────────────────────────────────
class TodoDateResult {
  const TodoDateResult({
    required this.type,
    this.date,
    this.rangeStart,
    this.rangeEnd,
    this.repeatStartDate,
    this.repeatEndDate,
    this.repeatType,
    this.repeatDays,
  });

  final TodoDateType type;

  // 일반
  final DateTime? date;

  // 기간
  final DateTime? rangeStart;
  final DateTime? rangeEnd;

  // 반복
  final DateTime? repeatStartDate;
  final DateTime? repeatEndDate;
  final String? repeatType;
  final List<int>? repeatDays;

  String get displayText {
    switch (type) {
      case TodoDateType.normal:
        if (date == null) return '';
        return '${date!.month}월 ${date!.day}일';
      case TodoDateType.someday:
        return '언젠가 할 일';
      case TodoDateType.range:
        if (rangeStart == null) return '기간 일정';
        final s = '${rangeStart!.month}월 ${rangeStart!.day}일';
        if (rangeEnd == null) return '$s ~';
        return '$s ~ ${rangeEnd!.month}월 ${rangeEnd!.day}일';
      case TodoDateType.repeat:
        return '반복 일정';
    }
  }
}

class TodoDateSheet extends StatefulWidget {
  const TodoDateSheet({
    super.key,
    this.initialDate,
    this.initialResult,
    this.embedded = false,
    this.disableRange = false,
    this.onConfirm,
    this.onBack,
  });
  final DateTime? initialDate;
  final TodoDateResult? initialResult;
  final bool embedded;
  final bool disableRange;
  final ValueChanged<TodoDateResult>? onConfirm;
  final VoidCallback? onBack;

  @override
  State<TodoDateSheet> createState() => _TodoDateSheetState();
}

class _TodoDateSheetState extends State<TodoDateSheet> {
  int _selectedTab = 0;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  bool _showRangeError = false;

  String _repeatType = '매주';
  final List<bool> _selectedWeekdays = List.filled(7, false);
  DateTime _repeatStartDate = DateTime.now();
  DateTime? _repeatEndDate;

  static const _weekdaysKo = ['일', '월', '화', '수', '목', '금', '토'];
  static const _repeatTypes = ['매일', '매주', '매월', '매년'];

  @override
  void initState() {
    super.initState();

    final init = widget.initialResult;
    if (init != null) {
      _selectedTab = init.type == TodoDateType.range
          ? 1
          : (init.type == TodoDateType.repeat ? 2 : 0);
      _selectedDay = init.date ?? widget.initialDate ?? DateTime.now();
      _rangeStart = init.rangeStart;
      _rangeEnd = init.rangeEnd;
      _repeatType = init.repeatType ??
          ((init.repeatDays != null && init.repeatDays!.length == 7)
              ? '매일'
              : '매주');
      _repeatStartDate =
          init.repeatStartDate ?? widget.initialDate ?? DateTime.now();
      _repeatEndDate = init.repeatEndDate;

      if (init.repeatDays != null && init.repeatDays!.isNotEmpty) {
        for (var idx in init.repeatDays!) {
          if (idx >= 0 && idx < 7) _selectedWeekdays[idx] = true;
        }
      } else {
        _selectedWeekdays[
        DateTime.now().weekday == 7 ? 0 : DateTime.now().weekday] = true;
      }
    } else {
      _selectedDay = widget.initialDate ?? DateTime.now();
      _repeatStartDate = _selectedDay!;
      _rangeStart = _selectedDay;
      _selectedWeekdays[
      DateTime.now().weekday == 7 ? 0 : DateTime.now().weekday] = true;
    }

    _focusedDay = _selectedDay ?? DateTime.now();
  }

  CalendarStyle _calStyle(BuildContext context) {
    final c = context.colors;
    return CalendarStyle(
      todayDecoration: BoxDecoration(
        color: c.calendarRangeHighlight,
        shape: BoxShape.circle,
      ),
      todayTextStyle:
      AppTextStyles.labelMedium.copyWith(color: c.textPrimary),
      selectedDecoration: const BoxDecoration(
        color: AppColors.calendarPoint,
        shape: BoxShape.circle,
      ),
      selectedTextStyle:
      AppTextStyles.labelMedium.copyWith(color: Colors.white),
      defaultTextStyle:
      AppTextStyles.labelMedium.copyWith(color: c.textPrimary),
      weekendTextStyle:
      AppTextStyles.labelMedium.copyWith(color: c.textPrimary),
      outsideTextStyle:
      AppTextStyles.labelMedium.copyWith(color: c.textHint),
      // 원 크기 32 (rowHeight 50 - 2*9)
      cellMargin: const EdgeInsets.all(9),
      // 전달/이후 달 날짜 숨김
      outsideDaysVisible: false,
    );
  }

  CalendarStyle _rangeCalStyle(BuildContext context) {
    final c = context.colors;
    return CalendarStyle(
      todayDecoration: BoxDecoration(
        color: c.calendarRangeHighlight,
        shape: BoxShape.circle,
      ),
      todayTextStyle:
      AppTextStyles.labelMedium.copyWith(color: c.textPrimary),
      rangeStartDecoration: const BoxDecoration(
        color: AppColors.calendarPoint,
        shape: BoxShape.circle,
      ),
      rangeStartTextStyle:
      AppTextStyles.labelMedium.copyWith(color: Colors.white),
      rangeEndDecoration: const BoxDecoration(
        color: AppColors.calendarPoint,
        shape: BoxShape.circle,
      ),
      rangeEndTextStyle:
      AppTextStyles.labelMedium.copyWith(color: Colors.white),
      rangeHighlightColor: Colors.transparent,
      rangeHighlightScale: 0.70,
      withinRangeTextStyle:
      AppTextStyles.labelMedium.copyWith(color: c.textPrimary),
      defaultTextStyle:
      AppTextStyles.labelMedium.copyWith(color: c.textPrimary),
      weekendTextStyle:
      AppTextStyles.labelMedium.copyWith(color: c.textPrimary),
      outsideTextStyle:
      AppTextStyles.labelMedium.copyWith(color: c.textHint),
      // 전달/이후 달 날짜 숨김 (기간 탭 전용)
      outsideDaysVisible: false,
    );
  }

  DaysOfWeekStyle _dowStyle(BuildContext context) {
    final c = context.colors;
    return DaysOfWeekStyle(
      dowTextFormatter: (d, _) => _weekdaysKo[d.weekday % 7],
      weekdayStyle:
      AppTextStyles.labelLarge.copyWith(color: c.textSecondary),
      weekendStyle:
      AppTextStyles.labelLarge.copyWith(color: c.textSecondary),
    );
  }

  void _showRepeatTypePicker(BuildContext context) {
    final c = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: c.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 8),
            ..._repeatTypes.map((type) {
              final sel = _repeatType == type;
              return ListTile(
                title: Text(type,
                    style: AppTextStyles.bodyMedium.copyWith(
                        color: sel ? AppColors.calendarPoint : c.textPrimary)),
                trailing: sel
                    ? const Icon(Icons.check,
                    color: AppColors.calendarPoint, size: 18)
                    : null,
                onTap: () {
                  setState(() {
                    if (_repeatType != type) {
                      _repeatType = type;
                      // 유형이 바뀌면 종료 날짜 초기화.
                      // 이전 유형의 날짜 목록과 새 유형의 목록이 달라서
                      // 선택된 날짜가 새 옵션에 없는 불일치 상태 방지.
                      _repeatEndDate = null;
                    }
                  });
                  Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  List<DateTime> _calcEndDateOptions() {
    final start = _repeatStartDate;
    final result = <DateTime>[];

    // 각 case 가 독립 실행되도록 명시적 return 사용
    // (Dart 버전에 따라 break 없으면 fall-through 가능성 있음)
    switch (_repeatType) {
      case '매일':
      // 매일 반복 = 모든 요일이 유효 → '매주'와 동일한 방식으로
      // 실제 다음 발생 날짜 20개를 순서대로 계산.
      // 고정 간격(7/14/30일)이 아닌 실제 날짜 패턴 기반.
        {
          var cur = start.add(const Duration(days: 1));
          int safety = 0;
          while (result.length < 20 && safety < 400) {
            result.add(cur);
            cur = cur.add(const Duration(days: 1));
            safety++;
          }
        }
        return result;
      case '매주':
        final selDays = [
          for (int i = 0; i < 7; i++) if (_selectedWeekdays[i]) i,
        ];
        if (selDays.isEmpty) selDays.add(start.weekday % 7);
        var cur = start.add(const Duration(days: 1));
        int safety = 0;
        while (result.length < 20 && safety < 400) {
          if (selDays.contains(cur.weekday % 7)) result.add(cur);
          cur = cur.add(const Duration(days: 1));
          safety++;
        }
        return result;
      case '매월':
        for (int i = 1; i <= 12; i++) {
          var m = start.month + i;
          var y = start.year;
          while (m > 12) {
            m -= 12;
            y++;
          }
          final maxDay = DateTime(y, m + 1, 0).day;
          result.add(DateTime(y, m, start.day.clamp(1, maxDay)));
        }
        return result;
      case '매년':
        for (int i = 1; i <= 5; i++) {
          result.add(DateTime(start.year + i, start.month, start.day));
        }
        return result;
    }
    return result;
  }

  void _showEndDateSheet(BuildContext context) {
    final c = context.colors;
    final options = _calcEndDateOptions();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.55,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: c.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('종료 날짜 선택',
                    style: AppTextStyles.titleSmall
                        .copyWith(color: c.textPrimary)),
              ),
            ),
            Divider(color: c.divider, height: 1),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    title: Text('없음',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: _repeatEndDate == null
                              ? AppColors.calendarPoint
                              : c.textPrimary,
                        )),
                    trailing: _repeatEndDate == null
                        ? const Icon(Icons.check,
                        color: AppColors.calendarPoint, size: 18)
                        : null,
                    onTap: () {
                      setState(() => _repeatEndDate = null);
                      Navigator.pop(context);
                    },
                  ),
                  Divider(
                      color: c.divider,
                      height: 1,
                      indent: 16,
                      endIndent: 16),
                  ...options.map((d) {
                    final isSel = _repeatEndDate != null &&
                        isSameDay(_repeatEndDate!, d);
                    final wd = _weekdaysKo[d.weekday % 7];
                    final label =
                        '${d.year}년 ${d.month}월 ${d.day}일 ($wd)';
                    return ListTile(
                      title: Text(label,
                          style: AppTextStyles.bodyMedium.copyWith(
                              color: isSel
                                  ? AppColors.calendarPoint
                                  : c.textPrimary)),
                      trailing: isSel
                          ? const Icon(Icons.check,
                          color: AppColors.calendarPoint, size: 18)
                          : null,
                      onTap: () {
                        setState(() => _repeatEndDate = d);
                        Navigator.pop(context);
                      },
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _endDateLabel() {
    if (_repeatEndDate == null) return '없음';
    final d = _repeatEndDate!;
    return '${d.month}월 ${d.day}일 (${_weekdaysKo[d.weekday % 7]})';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final embedded = widget.embedded;

    final headerSection = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _MascotBubble(message: '언제부터 언제까지 할까?'),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: _TabChip(
                  label: '일반',
                  selected: _selectedTab == 0,
                  onTap: () => setState(() => _selectedTab = 0)),
            ),
            if (!widget.disableRange) ...[
              const SizedBox(width: 8),
              Expanded(
                child: _TabChip(
                    label: '기간',
                    selected: _selectedTab == 1,
                    onTap: () => setState(() {
                      _selectedTab = 1;
                      _rangeStart = _selectedDay ?? DateTime.now();
                      _rangeEnd = null;
                    })),
              ),
            ],
            const SizedBox(width: 8),
            Expanded(
              child: _TabChip(
                  label: '반복',
                  selected: _selectedTab == 2,
                  onTap: () => setState(() => _selectedTab = 2)),
            ),
          ],
        ),
      ],
    );

    final tabContent = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_selectedTab == 0) ...[
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Text('${_focusedDay.month}월',
                style:
                AppTextStyles.titleMedium.copyWith(color: c.textPrimary)),
          ),
          const SizedBox(height: 10),
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            rowHeight: 50,
            daysOfWeekHeight: 32,
            selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
            rangeSelectionMode: RangeSelectionMode.disabled,
            onDaySelected: (sel, foc) => setState(() {
              _selectedDay = sel;
              _focusedDay = foc;
            }),
            onPageChanged: (foc) => setState(() => _focusedDay = foc),
            headerVisible: false,
            availableCalendarFormats: const {CalendarFormat.month: ''},
            daysOfWeekStyle: _dowStyle(context),
            calendarStyle: _calStyle(context),
          ),
        ],

        if (_selectedTab == 1) ...[
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Text('${_focusedDay.month}월',
                style:
                AppTextStyles.titleMedium.copyWith(color: c.textPrimary)),
          ),
          const SizedBox(height: 10),
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            rangeStartDay: _rangeStart,
            rangeEndDay: _rangeEnd,
            rowHeight: 50,
            daysOfWeekHeight: 32,
            rangeSelectionMode: RangeSelectionMode.toggledOn,
            onRangeSelected: (start, end, focusedDay) {
              setState(() {
                _rangeStart = start;
                _rangeEnd = end;
                _focusedDay = focusedDay;
                if (start != null && end != null) _showRangeError = false;
              });
            },
            onPageChanged: (foc) => setState(() => _focusedDay = foc),
            headerVisible: false,
            availableCalendarFormats: const {CalendarFormat.month: ''},
            daysOfWeekStyle: _dowStyle(context),
            calendarStyle: _rangeCalStyle(context),
            calendarBuilders: CalendarBuilders(
              rangeStartBuilder: (_, day, __) => _RangeLabelCell(
                day: day,
                label: '시작',
                isStart: true,
                showTail: _rangeEnd != null,
              ),
              rangeEndBuilder: (_, day, __) =>
                  _RangeLabelCell(day: day, label: '끝', isStart: false),
              withinRangeBuilder: (_, day, __) => _RangeMiddleCell(day: day),
              todayBuilder: (_, day, __) {
                final inRange = _rangeStart != null &&
                    _rangeEnd != null &&
                    day.isAfter(_rangeStart!.subtract(const Duration(days: 1))) &&
                    day.isBefore(_rangeEnd!.add(const Duration(days: 1)));
                if (inRange) return _RangeMiddleCell(day: day);
                return _TodayCell(day: day);
              },
            ),
          ),
        ],

        if (_selectedTab == 2) ...[
          GestureDetector(
            onTap: () => _showRepeatTypePicker(context),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 14),
              child: Row(
                children: [
                  Icon(Icons.repeat,
                      size: 18, color: AppColors.highlightElement),
                  const SizedBox(width: 10),
                  Text('반복 유형',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: c.textPrimary)),
                  const Spacer(),
                  Text(_repeatType,
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: c.textSecondary)),
                  const SizedBox(width: 2),
                  Icon(Icons.keyboard_arrow_down,
                      size: 16, color: c.textSecondary),
                ],
              ),
            ),
          ),
          Divider(color: c.divider),
          const SizedBox(height: 12),

          // 요일 원: 매일이면 전체 선택 고정, 매주면 개별 선택 가능
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final isDaily = _repeatType == '매일';
              final sel = isDaily || _selectedWeekdays[i];
              return GestureDetector(
                onTap: isDaily
                    ? null
                    : () => setState(
                        () => _selectedWeekdays[i] = !_selectedWeekdays[i]),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: sel ? AppColors.calendarPoint : c.surfaceAlt,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(_weekdaysKo[i],
                        style: AppTextStyles.labelLarge.copyWith(
                            color: sel ? Colors.white : c.textPrimary)),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),

          // 시작 날짜
          // 헤더 + 3휠 picker (년/월/일). 중간 divider 제거 — 알림 시트(time_sheet)의
          // 휠 영역과 동일한 호흡으로 보이도록 헤더와 picker 사이를 매끄럽게 연결.
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: c.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 16, color: AppColors.calendarPoint),
                      const SizedBox(width: 8),
                      Text('시작 날짜',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: c.textPrimary)),
                      const Spacer(),
                      Text(
                        '${_repeatStartDate.year}년 ${_repeatStartDate.month}월 ${_repeatStartDate.day}일',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: c.textSecondary),
                      ),
                    ],
                  ),
                ),
                _DateScrollPicker(
                  initialDate: _repeatStartDate,
                  onDateChanged: (d) => setState(() => _repeatStartDate = d),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          GestureDetector(
            onTap: () => _showEndDateSheet(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 16, color: c.textSecondary),
                  const SizedBox(width: 8),
                  Text('종료 날짜',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: c.textPrimary)),
                  const Spacer(),
                  Text(_endDateLabel(),
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: c.textSecondary)),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right,
                      size: 16, color: c.textHint),
                ],
              ),
            ),
          ),
        ],
      ],
    );

    // 기간 탭 인라인 에러 메시지
    final rangeErrorText = _showRangeError && _selectedTab == 1
        ? Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        '기간의 끝 날짜를 선택해주세요',
        style: AppTextStyles.bodySmall
            .copyWith(color: Colors.redAccent),
        textAlign: TextAlign.center,
      ),
    )
        : const SizedBox.shrink();

    final buttonRow = Row(
      children: [
        Expanded(
          child: _PrevButton(onTap: embedded ? widget.onBack : null),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DoitdoPrimaryButton(
            height: 48,
            label: '확인',
            onPressed: () {
              // 기간 탭: 시작 + 끝 모두 지정되어야 저장 가능
              if (_selectedTab == 1 &&
                  (_rangeStart == null || _rangeEnd == null)) {
                setState(() => _showRangeError = true);
                return;
              }

              final TodoDateResult result;
              switch (_selectedTab) {
                case 1:
                  result = TodoDateResult(
                    type: TodoDateType.range,
                    rangeStart: _rangeStart,
                    rangeEnd: _rangeEnd,
                  );
                case 2:
                  final selectedDayIndices = _repeatType == '매일'
                      ? List.generate(7, (i) => i)
                      : [for (int i = 0; i < 7; i++) if (_selectedWeekdays[i]) i];
                  result = TodoDateResult(
                    type: TodoDateType.repeat,
                    repeatStartDate: _repeatStartDate,
                    repeatEndDate: _repeatEndDate,
                    repeatType: _repeatType,
                    repeatDays: selectedDayIndices,
                  );
                default:
                  result = TodoDateResult(
                    type: TodoDateType.normal,
                    date: _selectedDay,
                  );
              }
              if (embedded) {
                widget.onConfirm?.call(result);
              } else {
                Navigator.of(context).pop(result);
              }
            },
          ),
        ),
      ],
    );

    if (embedded) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            headerSection,
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: tabContent,
              ),
            ),
            rangeErrorText,
            buttonRow,
          ],
        ),
      );
    }

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: c.border,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              headerSection,
              const SizedBox(height: 16),
              tabContent,
              const SizedBox(height: 24),
              rangeErrorText,
              buttonRow,
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 공통 상수 (기간 탭)
// rowHeight 50, 원 크기 32 (캘린더 기본 셀과 동일).
// _kCircleTop=9: 50px 행에서 32px 원이 정중앙. 막대도 같은 Y 영역.
// 라벨은 Align(topCenter) 로 9px 공간 최상단에 붙임 → 시각적으로 위로.
// ─────────────────────────────────────────────
const double _kCircleSize = 32.0;
const double _kCircleTop = 9.0;  // (50 - 32) / 2 — 중앙 정렬

class _RangeMiddleCell extends StatelessWidget {
  const _RangeMiddleCell({required this.day});
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Stack(
      children: [
        // 가운데 막대 — 행의 세로 정중앙에 _kCircleSize 만큼 깔림
        Positioned(
          top: _kCircleTop,
          left: 0,
          right: 0,
          height: _kCircleSize,
          child: Container(color: c.calendarRangeHighlight),
        ),
        // 날짜 텍스트 — 셀 전체에서 중앙 정렬 (기본 셀과 동일 Y)
        Center(
          child: Text(
            '${day.day}',
            style:
            AppTextStyles.labelMedium.copyWith(color: c.textPrimary),
          ),
        ),
      ],
    );
  }
}

class _RangeLabelCell extends StatelessWidget {
  const _RangeLabelCell({
    required this.day,
    required this.label,
    required this.isStart,
    this.showTail = true,
  });
  final DateTime day;
  final String label;  // '시작' or '끝'
  final bool isStart;
  final bool showTail;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellW = constraints.maxWidth;
        return Stack(
          children: [
            // 꼬리 막대 — 원과 같은 Y 영역에 연결
            if (showTail)
              Positioned(
                top: _kCircleTop,
                left: isStart ? cellW / 2 : 0,
                right: isStart ? 0 : cellW / 2,
                height: _kCircleSize,
                child: Container(color: context.colors.calendarRangeHighlight),
              ),
            // 시작/끝 라벨 — 9px 공간 최상단에 위치.
            // 음수 top 대신 폰트 사이즈를 작게(9) → 9px 안에 깔끔하게 들어가고
            // 시각적으로 위쪽에 떠있는 느낌. 잘림 없음.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: _kCircleTop,
              child: Align(
                alignment: Alignment.topCenter,
                child: Text(
                  label,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.calendarPoint,
                    fontSize: 9,
                    height: 1,
                  ),
                ),
              ),
            ),
            // 원 — 행 중앙 정렬 (날짜 y=25, 기본 셀과 동일)
            Center(
              child: Container(
                width: _kCircleSize,
                height: _kCircleSize,
                decoration: const BoxDecoration(
                  color: AppColors.calendarPoint,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${day.day}',
                  style: AppTextStyles.labelMedium
                      .copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TodayCell extends StatelessWidget {
  const _TodayCell({required this.day});
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Container(
        width: _kCircleSize,
        height: _kCircleSize,
        decoration: BoxDecoration(
          color: c.calendarRangeHighlight,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          '${day.day}',
          style: AppTextStyles.labelMedium.copyWith(color: c.textPrimary),
        ),
      ),
    );
  }
}

class _MascotBubble extends StatelessWidget {
  const _MascotBubble({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const CharacterMascotImage(size: 36),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const BoxDecoration(
            color: AppColors.bubbleBg,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(12),
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
          child: Text(
            message,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.calendarDateText,
            ),
          ),
        ),
      ],
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.calendarPoint : c.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: AppTextStyles.bodyMedium.copyWith(
                color: selected ? Colors.white : c.textPrimary)),
      ),
    );
  }
}

class _PrevButton extends StatelessWidget {
  const _PrevButton({this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap ?? () => Navigator.of(context).pop(),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.loginBtnOff,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text('이전',
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
    );
  }
}

// ─────────────────────────────────────────────
// 시작 날짜 picker — 년/월/일 3휠
// time_sheet 의 알림 picker 와 동일한 톤(itemExtent 48, perspective 0.002,
// 선택 항목은 textPrimary + bodyLarge, 그 외 textHint + bodyMedium).
//
// 월/년 변경 시 일(day)이 해당 월 최대일을 넘으면 자동 보정.
//   ex) 1월 31일 → 2월로 변경 → 2월 28/29일로 클램프 + day 휠 애니메이션.
// ─────────────────────────────────────────────
class _DateScrollPicker extends StatefulWidget {
  const _DateScrollPicker({
    required this.initialDate,
    required this.onDateChanged,
  });
  final DateTime initialDate;
  final ValueChanged<DateTime> onDateChanged;

  @override
  State<_DateScrollPicker> createState() => _DateScrollPickerState();
}

class _DateScrollPickerState extends State<_DateScrollPicker> {
  static const int _yearStart = 2020;
  static const int _yearEnd = 2035;
  static const int _yearCount = _yearEnd - _yearStart + 1;

  late int _year;
  late int _month;
  late int _day;

  late FixedExtentScrollController _yearCtrl;
  late FixedExtentScrollController _monthCtrl;
  late FixedExtentScrollController _dayCtrl;

  @override
  void initState() {
    super.initState();
    _year = widget.initialDate.year.clamp(_yearStart, _yearEnd);
    _month = widget.initialDate.month;
    _day = widget.initialDate.day;

    _yearCtrl =
        FixedExtentScrollController(initialItem: _year - _yearStart);
    _monthCtrl = FixedExtentScrollController(initialItem: _month - 1);
    _dayCtrl = FixedExtentScrollController(initialItem: _day - 1);
  }

  @override
  void dispose() {
    _yearCtrl.dispose();
    _monthCtrl.dispose();
    _dayCtrl.dispose();
    super.dispose();
  }

  int _daysInMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;

  void _emit() {
    widget.onDateChanged(DateTime(_year, _month, _day));
  }

  /// 월/년 변경 후 day 가 해당 월 최대일을 넘으면 보정.
  /// day 휠 컨트롤러도 다음 프레임에 애니메이션으로 맞춰준다.
  void _clampDayIfNeeded() {
    final maxDay = _daysInMonth(_year, _month);
    if (_day > maxDay) {
      _day = maxDay;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _dayCtrl.animateToItem(
          _day - 1,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _onYearChanged(int i) {
    setState(() {
      _year = _yearStart + i;
      _clampDayIfNeeded();
    });
    _emit();
  }

  void _onMonthChanged(int i) {
    setState(() {
      _month = i + 1;
      _clampDayIfNeeded();
    });
    _emit();
  }

  void _onDayChanged(int i) {
    final newDay = i + 1;
    final maxDay = _daysInMonth(_year, _month);
    if (newDay > maxDay) {
      // 31일 휠에서 28/29/30일 월일 때 → 최대일로 스냅백.
      setState(() => _day = maxDay);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _dayCtrl.animateToItem(
          maxDay - 1,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      });
    } else {
      setState(() => _day = newDay);
    }
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // 애플 picker 스펙
    // - itemExtent 36: 한 줄에 5개(중앙 + 위 2 + 아래 2) 보이는 컴팩트한 간격
    // - 전체 높이 180: 위/아래 여백 + 중앙 선택 영역
    // - 중앙 highlight bar 가 picker 전체 폭을 가로지르며 선택 영역 시각화
    const itemExtent = 36.0;
    const wheelHeight = 180.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: SizedBox(
        height: wheelHeight,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1) 중앙 선택 highlight bar
            IgnorePointer(
              child: Container(
                height: itemExtent,
                decoration: BoxDecoration(
                  color: c.surfaceAlt,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            // 2) 3개 휠
            Row(
              children: [
                Expanded(
                  child: _wheel(
                    controller: _yearCtrl,
                    itemCount: _yearCount,
                    itemExtent: itemExtent,
                    onChanged: _onYearChanged,
                    isSelected: (i) => _yearStart + i == _year,
                    label: (i) => '${_yearStart + i}년',
                    colors: c,
                  ),
                ),
                Expanded(
                  child: _wheel(
                    controller: _monthCtrl,
                    itemCount: 12,
                    itemExtent: itemExtent,
                    onChanged: _onMonthChanged,
                    isSelected: (i) => i + 1 == _month,
                    label: (i) => '${i + 1}월',
                    colors: c,
                  ),
                ),
                Expanded(
                  child: _wheel(
                    controller: _dayCtrl,
                    itemCount: 31,
                    itemExtent: itemExtent,
                    onChanged: _onDayChanged,
                    isSelected: (i) => i + 1 == _day,
                    label: (i) => '${i + 1}일',
                    colors: c,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _wheel({
    required FixedExtentScrollController controller,
    required int itemCount,
    required double itemExtent,
    required ValueChanged<int> onChanged,
    required bool Function(int) isSelected,
    required String Function(int) label,
    required DoitdoColors colors,
  }) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: itemExtent,
      perspective: 0.001,
      diameterRatio: 1.5,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: onChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: itemCount,
        builder: (_, i) {
          if (i < 0 || i >= itemCount) return null;
          final sel = isSelected(i);
          return Center(
            child: Text(
              label(i),
              style: AppTextStyles.bodyLarge.copyWith(
                color: sel ? colors.textPrimary : colors.textHint,
              ),
            ),
          );
        },
      ),
    );
  }
}