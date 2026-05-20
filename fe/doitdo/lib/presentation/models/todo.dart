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
      '공부' => const TodoCategory(name: '공부', colorKey: CategoryColorKey.study),
      _ => TodoCategory(name: name, colorKey: CategoryColorKey.etc),
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
    this.categoryId,
    this.colorHex,
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
    this.recurrenceGroupId,
  });

  final String id;
  final String title;
  final TodoCategory category;
  final int? categoryId;
  final String? colorHex;
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

  /// 같은 반복 흐름임을 식별하는 group id (서버 발급).
  ///
  /// scope=from 으로 잘려 새 마스터가 생기더라도, 둘 다 같은 recurrenceGroupId 를
  /// 가져 사용자 입장에서 "하나의 시리즈" 로 묶어 표현/조작할 수 있다.
  /// 예: 시리즈 전체 삭제, 시리즈 시각적 구분, 분할된 항목을 같은 todo 의 변경으로 보여주기.
  ///
  /// - RECURRING 마스터: 자기 id (group head) 가 들어옴
  /// - RECURRING 의 NORMAL 파생 인스턴스: 마스터의 groupId 상속
  /// - 일반 NORMAL/PERIOD/SOMEDAY: null
  /// - 백필 안 된 레거시 RECURRING: null
  final int? recurrenceGroupId;

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
        if (repeatType == '매일' || (repeatDays != null && repeatDays!.length == 7)) {
          if (repeatStartDate == null) return '매일 반복';
          return '매일 | ${repeatStartDate!.month}월 ${repeatStartDate!.day}일부터';
        }
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
    int? categoryId,
    String? colorHex,
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
    int? recurrenceGroupId,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId,
      colorHex: colorHex ?? this.colorHex,
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
      recurrenceGroupId: recurrenceGroupId ?? this.recurrenceGroupId,
    );
  }
}