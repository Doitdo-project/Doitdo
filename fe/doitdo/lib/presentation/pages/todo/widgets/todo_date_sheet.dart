import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:doitdo/core/theme/app_colors.dart';
import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/models/todo.dart'; // ✏️ 추가: TodoDateType 이 todo.dart 로 이동됨
import 'package:doitdo/presentation/widgets/common/doitdo_primary_button.dart';

// ─────────────────────────────────────────────
// 날짜 선택 결과 모델
// ─────────────────────────────────────────────
// ✏️ 삭제: enum TodoDateType { normal, range, repeat }
//         → todo.dart 로 이동. 여기서 정의하면 todo.dart 와 충돌

class TodoDateResult {
  const TodoDateResult({
    required this.type,
    this.date,
    this.rangeStart,
    this.rangeEnd,
    this.repeatStartDate,
    this.repeatEndDate,
    this.repeatType,
    this.repeatDays, // ✏️ 추가: 선택된 요일 인덱스 (0=일~6=토)
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
  final List<int>? repeatDays; // ✏️ 추가

  /// todo_add_sheet 기간 행에 표시할 텍스트
  String get displayText {
    switch (type) {
      case TodoDateType.normal:
        if (date == null) return '';
        return '${date!.month}월 ${date!.day}일';
      case TodoDateType.someday:
        return '언제가 할 일';
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
  const TodoDateSheet({super.key, this.initialDate, this.initialResult});
  final DateTime? initialDate;
  final TodoDateResult? initialResult;

  @override
  State<TodoDateSheet> createState() => _TodoDateSheetState();
}

class _TodoDateSheetState extends State<TodoDateSheet> {
  int _selectedTab = 0;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  String _repeatType = '매주';
  final List<bool> _selectedWeekdays = List.filled(7, false);
  DateTime _repeatStartDate = DateTime.now();
  DateTime? _repeatEndDate;

  static const _weekdaysKo = ['일', '월', '화', '수', '목', '금', '토'];
  static const _repeatTypes = ['매주', '매월', '매년'];

  @override
  void initState() {
    super.initState();

    // 초기값 복원
    final init = widget.initialResult;
    if (init != null) {
      _selectedTab = init.type == TodoDateType.range ? 1 : (init.type == TodoDateType.repeat ? 2 : 0);
      _selectedDay = init.date ?? widget.initialDate ?? DateTime.now();
      _rangeStart = init.rangeStart;
      _rangeEnd = init.rangeEnd;
      _repeatType = init.repeatType ?? '매주';
      _repeatStartDate = init.repeatStartDate ?? widget.initialDate ?? DateTime.now();
      _repeatEndDate = init.repeatEndDate;

      if (init.repeatDays != null && init.repeatDays!.isNotEmpty) {
        for (var idx in init.repeatDays!) {
          if (idx >= 0 && idx < 7) _selectedWeekdays[idx] = true;
        }
      } else {
        // 복원할 요일이 없으면 오늘 요일 기본 선택
        _selectedWeekdays[DateTime.now().weekday == 7 ? 0 : DateTime.now().weekday] = true;
      }
    } else {
      _selectedDay = widget.initialDate ?? DateTime.now();
      _repeatStartDate = _selectedDay!;
      _rangeStart = _selectedDay;
      _selectedWeekdays[DateTime.now().weekday == 7 ? 0 : DateTime.now().weekday] = true;
    }

    _focusedDay = _selectedDay ?? DateTime.now();
  }

  // ── 달력 공통 스타일 (일반 탭) ─────────────────────
  CalendarStyle _calStyle(BuildContext context) {
    final c = context.colors;
    return CalendarStyle(
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
      selectedTextStyle:
      AppTextStyles.labelMedium.copyWith(color: Colors.white),
      defaultTextStyle:
      AppTextStyles.labelMedium.copyWith(color: c.textPrimary),
      weekendTextStyle:
      AppTextStyles.labelMedium.copyWith(color: c.textPrimary),
      outsideTextStyle:
      AppTextStyles.labelMedium.copyWith(color: c.textHint),
    );
  }

  // ── 달력 스타일 (기간 탭) — 오늘 날짜 강조 없음 ─────
  CalendarStyle _rangeCalStyle(BuildContext context) {
    final c = context.colors;
    return CalendarStyle(
      // 오늘 날짜를 일반 날짜와 동일하게 표시 (강조 없음)
      todayDecoration: const BoxDecoration(
        color: AppColors.homeCalendarSelectedBg,
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

      // ✅ [수정 1] 여기를 반드시 투명색으로 바꿔야 달력 패키지의 기본 형광펜이 꺼집니다!
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

  // ── 반복 유형 선택 바텀시트 ─────────────
  void _showRepeatTypePicker(BuildContext context) {
    final c = context.colors;
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SafeArea(
        top: false,
        child: Container(
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
                        color:
                        sel ? AppColors.calendarPoint : c.textPrimary)),
                trailing: sel
                    ? const Icon(Icons.check,
                    color: AppColors.calendarPoint, size: 18)
                    : null,
                onTap: () {
                  setState(() => _repeatType = type);
                  Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
        ),
      ),
    );
  }

  // ── 종료 날짜 계산 (반복 패턴 기반) ─────
  List<DateTime> _calcEndDateOptions() {
    final start = _repeatStartDate;
    final result = <DateTime>[];

    switch (_repeatType) {
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
      case '매년':
        for (int i = 1; i <= 5; i++) {
          result.add(DateTime(start.year + i, start.month, start.day));
        }
    }
    return result;
  }

  // ── 종료 날짜 드롭다운 바텀시트 ─────────
  void _showEndDateSheet(BuildContext context) {
    final c = context.colors;
    final options = _calcEndDateOptions();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SafeArea(
        top: false,
        child: Container(
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

    return Container(
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
                    color: c.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const _MascotBubble(message: '언제부터 언제까지 할까?'),
            const SizedBox(height: 16),

            // 탭 버튼 — Expanded 로 균등 분배
            Row(
              children: [
                Expanded(
                  child: _TabChip(
                      label: '일반',
                      selected: _selectedTab == 0,
                      onTap: () => setState(() => _selectedTab = 0)),
                ),
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
                const SizedBox(width: 8),
                Expanded(
                  child: _TabChip(
                      label: '반복',
                      selected: _selectedTab == 2,
                      onTap: () => setState(() => _selectedTab = 2)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ══════════════════════════
            // 일반 탭
            // ══════════════════════════
            if (_selectedTab == 0) ...[
              Padding(
                padding: const EdgeInsets.only(left: 12.0), // 👈 글자만 우측으로 살짝(약 12px) 이동
                child: Text('${_focusedDay.month}월',
                    style: AppTextStyles.titleMedium.copyWith(color: c.textPrimary)),
              ),
              const SizedBox(height: 8),
              TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
                rangeSelectionMode: RangeSelectionMode.disabled,
                onDaySelected: (sel, foc) =>
                    setState(() {
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

            // ══════════════════════════
            // 기간 탭 — onRangeSelected로 start/end 관리
            //   진입 시 당일이 시작날짜로 표시됨
            //   다른 날짜 탭 → 끝 날짜 지정
            //   끝 지정 후 다시 탭 → start 리셋 (table_calendar 기본 동작)
            // ══════════════════════════
            if (_selectedTab == 1) ...[
              Padding(
                padding: const EdgeInsets.only(left: 12.0), // 👈 글자만 우측으로 살짝(약 12px) 이동
                child: Text('${_focusedDay.month}월',
                    style: AppTextStyles.titleMedium.copyWith(color: c.textPrimary)),
              ),
              const SizedBox(height: 8),
              TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                rangeStartDay: _rangeStart,
                rangeEndDay: _rangeEnd,
                rowHeight: 54,
                // ✅ toggledOn: rangeStartBuilder / rangeEndBuilder / withinRangeBuilder 정상 호출됨
                rangeSelectionMode: RangeSelectionMode.toggledOn,
                onRangeSelected: (start, end, focusedDay) {
                  setState(() {
                    _rangeStart = start;
                    _rangeEnd = end;
                    _focusedDay = focusedDay;
                  });
                },
                onPageChanged: (foc) => setState(() => _focusedDay = foc),
                headerVisible: false,
                availableCalendarFormats: const {CalendarFormat.month: ''},
                daysOfWeekStyle: _dowStyle(context),
                // ✅ 기간 탭 전용 스타일: 오늘 날짜 강조 없음
                calendarStyle: _rangeCalStyle(context),
                calendarBuilders: CalendarBuilders(
                  // 시작 날짜 셀: '시작' 라벨 + 오렌지 원
                  rangeStartBuilder: (_, day, __) =>
                      _RangeLabelCell(day: day, label: '시작', isStart: true,showTail: _rangeEnd != null,),
                  // 끝 날짜 셀: '끝' 라벨 + 오렌지 원
                  rangeEndBuilder: (_, day, __) =>
                      _RangeLabelCell(day: day, label: '끝', isStart: false),
                  // 범위 내 날짜 셀: 연한 배경만
                  withinRangeBuilder: (_, day, __) =>
                      _RangeMiddleCell(day: day),
                  // table_calendar 우선순위:
                  //   rangeStart/End > today > withinRange
                  // 오늘이 range 안에 있으면 todayBuilder가 호출되므로
                  // 여기서 range 포함 여부를 직접 체크해 분기 처리
                  todayBuilder: (_, day, __) {
                    final inRange = _rangeStart != null &&
                        _rangeEnd != null &&
                        day.isAfter(_rangeStart!.subtract(const Duration(days: 1))) &&
                        day.isBefore(_rangeEnd!.add(const Duration(days: 1)));
                    if (inRange) return _RangeMiddleCell(day: day);
                    // range 밖: 연한 원 (homeCalendarSelectedBg)
                    return _TodayCell(day: day);
                  },

                ),
              ),
            ],

            // ══════════════════════════
            // 반복 탭
            // ══════════════════════════
            if (_selectedTab == 2) ...[
              GestureDetector(
                onTap: () => _showRepeatTypePicker(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
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

              if (_repeatType == '매주') ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (i) {
                    final sel = _selectedWeekdays[i];
                    return GestureDetector(
                      onTap: () => setState(
                              () => _selectedWeekdays[i] = !_selectedWeekdays[i]),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color:
                          sel ? AppColors.calendarPoint : c.surfaceAlt,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(_weekdaysKo[i],
                              style: AppTextStyles.labelLarge.copyWith(
                                  color: sel
                                      ? Colors.white
                                      : c.textPrimary)),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
              ],

              // 시작 날짜
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
                    Divider(color: c.divider, height: 1),
                    _DateScrollPicker(
                      initialDate: _repeatStartDate,
                      onDateChanged: (d) =>
                          setState(() => _repeatStartDate = d),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 종료 날짜 (계산된 날짜 드롭다운)
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

            const SizedBox(height: 24),

            Row(
              children: [
                const Expanded(child: _PrevButton()),
                const SizedBox(width: 8),
                Expanded(
                  child: DoitdoPrimaryButton(
                    label: '확인',
                    onPressed: () {
                      final TodoDateResult result;
                      switch (_selectedTab) {
                        case 1:
                          result = TodoDateResult(
                            type: TodoDateType.range,
                            rangeStart: _rangeStart,
                            rangeEnd: _rangeEnd,
                          );
                        case 2:
                        // ✏️ 수정: 선택된 요일 인덱스 목록 저장
                          final selectedDayIndices = [
                            for (int i = 0; i < 7; i++)
                              if (_selectedWeekdays[i]) i,
                          ];
                          result = TodoDateResult(
                            type: TodoDateType.repeat,
                            repeatStartDate: _repeatStartDate,
                            repeatEndDate: _repeatEndDate,
                            repeatType: _repeatType,
                            repeatDays: selectedDayIndices, // ✏️ 추가
                          );
                        default:
                          result = TodoDateResult(
                            type: TodoDateType.normal,
                            date: _selectedDay,
                          );
                      }
                      Navigator.of(context).pop(result);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 공통 상수
// rowHeight=54, 라벨=12, gap=2 → 원 top=14, size=36
// ─────────────────────────────────────────────
const double _kLabelH = 12.0;
const double _kGap = 2.0;
const double _kCircleTop = _kLabelH + _kGap; // 14.0
const double _kCircleSize = 36.0;

// ─────────────────────────────────────────────
// 기간 탭: 범위 내 날짜 셀 (가운데 날짜들)
// withinRangeBuilder에서 호출됨
// ─────────────────────────────────────────────
class _RangeMiddleCell extends StatelessWidget {
  const _RangeMiddleCell({required this.day});
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Stack(
      children: [
        // 배경: 원의 시작 위치(_kCircleTop)부터 원의 크기(_kCircleSize)만큼만 그림
        Positioned(
          top: _kCircleTop,
          left: 0,
          right: 0,
          height: _kCircleSize,
          child: Container(color: AppColors.homeCalendarSelectedBg),
        ),
        // 날짜 텍스트: 원 영역 중앙에 배치
        Positioned(
          top: _kCircleTop,
          left: 0,
          right: 0,
          height: _kCircleSize,
          child: Center(
            child: Text(
              '${day.day}',
              style:
              AppTextStyles.labelMedium.copyWith(color: c.textPrimary),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// 기간 탭: 시작·끝 라벨 셀
// rangeStartBuilder / rangeEndBuilder에서 호출됨
// ─────────────────────────────────────────────
class _RangeLabelCell extends StatelessWidget {
  const _RangeLabelCell({
    required this.day,
    required this.label,
    required this.isStart,
    this.showTail = true,
  });
  final DateTime day;
  final String label;
  final bool isStart;
  final bool showTail;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellW = constraints.maxWidth;

        return Stack(
          children: [
            // ✅ [수정 2] 핵심! showTail이 true일 때만 절반 배경(꼬리)을 그립니다!
            if (showTail)
              Positioned(
                top: _kCircleTop,
                left: isStart ? cellW / 2 : 0,
                right: isStart ? 0 : cellW / 2,
                height: _kCircleSize,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.homeCalendarSelectedBg,
                    borderRadius: BorderRadius.only(
                      topLeft: isStart
                          ? Radius.circular(_kCircleSize / 2)
                          : Radius.zero,
                      bottomLeft: isStart
                          ? Radius.circular(_kCircleSize / 2)
                          : Radius.zero,
                      topRight: !isStart
                          ? Radius.circular(_kCircleSize / 2)
                          : Radius.zero,
                      bottomRight: !isStart
                          ? Radius.circular(_kCircleSize / 2)
                          : Radius.zero,
                    ),
                  ),
                ),
              ),

            // 상단 라벨(시작/끝) + 날짜 원
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: _kLabelH,
                    child: Text(
                      label,
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.calendarPoint),
                    ),
                  ),
                  const SizedBox(height: _kGap),
                  Container(
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
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// 기간 탭: 오늘 날짜를 일반 날짜처럼 렌더링 (강조 없음)
// todayBuilder에서 사용 — 오늘이 start/end/within이면 각 builder가 우선
// ─────────────────────────────────────────────
class _PlainDayCell extends StatelessWidget {
  const _PlainDayCell({required this.day});
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Text(
        '${day.day}',
        style: AppTextStyles.labelMedium.copyWith(color: c.textPrimary),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 기간 탭: 오늘 날짜 — range 밖일 때 연한 원으로 표시
// range 안일 때는 todayBuilder에서 _RangeMiddleCell로 분기됨
// ─────────────────────────────────────────────
class _TodayCell extends StatelessWidget {
  const _TodayCell({required this.day});
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Container(
        width: 38,
        height: 38,
        decoration: const BoxDecoration(
          color: AppColors.homeCalendarSelectedBg,
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
        Image.asset(
          'assets/images/Dooit.png',
          width: 26,
          height: 26,
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.bubbleBg,
            borderRadius: const BorderRadius.only(
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
        padding: const EdgeInsets.symmetric(vertical: 9),
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
  const _PrevButton();
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => Navigator.of(context).pop(),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.loginBtnOff,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: Text('이전',
          style: AppTextStyles.bodyLarge.copyWith(color: Colors.white)),
    );
  }
}

class _DateScrollPicker extends StatefulWidget {
  const _DateScrollPicker(
      {required this.initialDate, required this.onDateChanged});
  final DateTime initialDate;
  final ValueChanged<DateTime> onDateChanged;

  @override
  State<_DateScrollPicker> createState() => _DateScrollPickerState();
}

class _DateScrollPickerState extends State<_DateScrollPicker> {
  static final _origin = DateTime(2020, 1, 1);
  static const _totalDays = 365 * 12;
  static const _wd = ['일', '월', '화', '수', '목', '금', '토'];

  late int _sel;
  late FixedExtentScrollController _ctrl;

  @override
  void initState() {
    super.initState();
    _sel = widget.initialDate
        .difference(_origin)
        .inDays
        .clamp(0, _totalDays - 1);
    _ctrl = FixedExtentScrollController(initialItem: _sel);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  DateTime _at(int i) => _origin.add(Duration(days: i));
  String _fmt(DateTime d) =>
      '${d.month}월 | ${d.day}일 (${_wd[d.weekday % 7]})';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: 144,
      child: ListWheelScrollView.useDelegate(
        controller: _ctrl,
        itemExtent: 48,
        perspective: 0.002,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: (i) {
          setState(() => _sel = i);
          widget.onDateChanged(_at(i));
        },
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: _totalDays,
          builder: (_, i) {
            if (i < 0 || i >= _totalDays) return null;
            final s = i == _sel;
            return Center(
              child: Text(_fmt(_at(i)),
                  style: (s
                      ? AppTextStyles.bodyLarge
                      : AppTextStyles.bodySmall)
                      .copyWith(color: s ? c.textPrimary : c.textHint)),
            );
          },
        ),
      ),
    );
  }
}
