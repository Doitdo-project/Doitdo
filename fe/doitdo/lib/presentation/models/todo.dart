import 'package:flutter/material.dart'; // TimeOfDay + @immutable

// ─────────────────────────────────────────────
// TodoDateType
// ─────────────────────────────────────────────
enum TodoDateType { normal, someday, range, repeat }

// ─────────────────────────────────────────────
// CategoryColorKey
// ─────────────────────────────────────────────
enum CategoryColorKey {
  health,
  study,
  work,
  hobby,
  etc,
  exercise,
}

// ─────────────────────────────────────────────
// TodoCategory
// ─────────────────────────────────────────────
@immutable
class TodoCategory {
  const TodoCategory({required this.name, required this.colorKey});

  final String name;
  final CategoryColorKey colorKey;

  TodoCategory copyWith({String? name, CategoryColorKey? colorKey}) =>
      TodoCategory(
        name: name ?? this.name,
        colorKey: colorKey ?? this.colorKey,
      );

  static TodoCategory fromName(String name) {
    return switch (name) {
      '운동' => const TodoCategory(name: '운동', colorKey: CategoryColorKey.exercise),
      '업무' => const TodoCategory(name: '업무', colorKey: CategoryColorKey.work),
      '건강' => const TodoCategory(name: '건강', colorKey: CategoryColorKey.health),
      '취미' => const TodoCategory(name: '취미', colorKey: CategoryColorKey.hobby),
      _    => const TodoCategory(name: '공부', colorKey: CategoryColorKey.study),
    };
  }
}

// ─────────────────────────────────────────────
// Todo
// ─────────────────────────────────────────────
@immutable
class Todo {
  const Todo({
    required this.id,
    required this.title,
    required this.category,
    this.categoryId, // ✏️ 추가: 서버와 통신할 진짜 카테고리 ID
    required this.isDone,
    this.memo,
    this.alarmTime,
    this.alarmEnabled = false,
    this.dateType = TodoDateType.normal,
    this.date,
    this.rangeStart,
    this.rangeEnd,
    this.repeatType,
    this.repeatStartDate,
    this.repeatEndDate,
    this.period,
    this.repeatDays,
  });

  final String id;
  final String title;
  final TodoCategory category;
  final int? categoryId; // ✏️ 추가
  final bool isDone;
  final String? memo;
  final TimeOfDay? alarmTime;
  final bool alarmEnabled;
  final TodoDateType dateType;
  final DateTime? date;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;
  final String? repeatType;
  final DateTime? repeatStartDate;
  final DateTime? repeatEndDate;
  final int? period;
  final List<int>? repeatDays;

  String get dateDisplayText {
    switch (dateType) {
      case TodoDateType.normal:
        if (date == null) return '날짜 없음';
        return '${date!.month}월 ${date!.day}일';
      case TodoDateType.someday:
        return '언제가 할 일';
      case TodoDateType.range:
        final start = rangeStart ?? date;
        if (start == null) return '기간 미설정';
        final s = '${start.month}월 ${start.day}일';
        if (rangeEnd == null) return '$s ~';
        return '$s ~ ${rangeEnd!.month}월 ${rangeEnd!.day}일';
      case TodoDateType.repeat:
        if (repeatDays != null && repeatDays!.isNotEmpty) {
          const ko = ['일', '월', '화', '수', '목', '금', '토'];
          final days = repeatDays!.map((i) => ko[i]).join('·');
          return '매주 $days 반복';
        }
        final type = repeatType ?? '';
        if (repeatStartDate == null) return '$type 반복';
        return '$type | ${repeatStartDate!.month}월 ${repeatStartDate!.day}일부터';
    }
  }

  String get alarmDisplayText {
    if (!alarmEnabled || alarmTime == null) return '알림 없음';
    final h = alarmTime!.hour;
    final m = alarmTime!.minute.toString().padLeft(2, '0');
    final p = h < 12 ? '오전' : '오후';
    final display = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$p $display:$m';
  }

  Todo copyWith({
    String? id,
    String? title,
    TodoCategory? category,
    int? categoryId, // ✏️ 추가
    bool? isDone,
    String? memo,
    TimeOfDay? alarmTime,
    bool? alarmEnabled,
    TodoDateType? dateType,
    DateTime? date,
    DateTime? rangeStart,
    DateTime? rangeEnd,
    String? repeatType,
    DateTime? repeatStartDate,
    DateTime? repeatEndDate,
    int? period,
    List<int>? repeatDays,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId, // ✏️ 추가
      isDone: isDone ?? this.isDone,
      memo: memo ?? this.memo,
      alarmTime: alarmTime ?? this.alarmTime,
      alarmEnabled: alarmEnabled ?? this.alarmEnabled,
      dateType: dateType ?? this.dateType,
      date: date ?? this.date,
      rangeStart: rangeStart ?? this.rangeStart,
      rangeEnd: rangeEnd ?? this.rangeEnd,
      repeatType: repeatType ?? this.repeatType,
      repeatStartDate: repeatStartDate ?? this.repeatStartDate,
      repeatEndDate: repeatEndDate ?? this.repeatEndDate,
      period: period ?? this.period,
      repeatDays: repeatDays ?? this.repeatDays,
    );
  }
}