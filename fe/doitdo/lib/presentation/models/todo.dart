import 'package:flutter/material.dart'; // TimeOfDay + @immutable

/// 할 일 / 카테고리 표시용 모델.
///
/// 기존 모델(id, title, category, isDone)을 유지하면서
/// 메모·알림·날짜 필드를 optional 로 추가했습니다.
/// API 연동 시점에 `domain/entities/todo.dart` 의
/// 실제 엔티티로 교체하거나 매핑하도록 합니다.

// ─────────────────────────────────────────────
// TodoDateType (todo_date_sheet.dart 에서 이동)
// todo_date_sheet.dart 는 이 파일을 import 하여 사용
// ─────────────────────────────────────────────
enum TodoDateType { normal, range, repeat }

// ─────────────────────────────────────────────
// CategoryColorKey
//   기존 값 유지 : health, study, work, hobby, etc
//   신규 추가    : exercise (운동 카테고리)
// ─────────────────────────────────────────────
enum CategoryColorKey {
  health,   // 건강
  study,    // 공부
  work,     // 업무
  hobby,    // 취미
  etc,      // 기타 (기존 호환용)
  exercise, // 운동 (신규)
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

  /// 카테고리 이름 → TodoCategory 변환 (TodoAddSheet 에서 사용)
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
//   ✅ 기존 required 필드(id, title, category, isDone) 그대로 유지
//   ✅ 신규 필드는 전부 optional — 기존 const Todo(...) 코드 호환
// ─────────────────────────────────────────────
@immutable
class Todo {
  const Todo({
    required this.id,
    required this.title,
    required this.category,
    required this.isDone,
    // ── 신규 optional 필드 ──────────────────
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
  });

  // 기존
  final String id;
  final String title;
  final TodoCategory category;
  final bool isDone;

  // 메모
  final String? memo;

  // 알림
  final TimeOfDay? alarmTime;
  final bool alarmEnabled;

  // 날짜
  final TodoDateType dateType;
  final DateTime? date;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;
  final String? repeatType;
  final DateTime? repeatStartDate;
  final DateTime? repeatEndDate;

  // ── 표시용 날짜 텍스트 ──────────────────────
  String get dateDisplayText {
    switch (dateType) {
      case TodoDateType.normal:
        if (date == null) return '날짜 없음';
        return '${date!.month}월 ${date!.day}일';
      case TodoDateType.range:
        if (rangeStart == null) return '기간 미설정';
        final s = '${rangeStart!.month}월 ${rangeStart!.day}일';
        if (rangeEnd == null) return '$s ~';
        return '$s ~ ${rangeEnd!.month}월 ${rangeEnd!.day}일';
      case TodoDateType.repeat:
        final type = repeatType ?? '';
        if (repeatStartDate == null) return '$type 반복';
        return '$type | ${repeatStartDate!.month}월 ${repeatStartDate!.day}일부터';
    }
  }

  // ── 표시용 알림 텍스트 ──────────────────────
  String get alarmDisplayText {
    if (!alarmEnabled || alarmTime == null) return '알림 없음';
    final h = alarmTime!.hour;
    final m = alarmTime!.minute.toString().padLeft(2, '0');
    final period = h < 12 ? '오전' : '오후';
    final display = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$period $display:$m';
  }

  // ── copyWith (기존 isDone 파라미터 포함, 전체 필드로 확장) ──
  Todo copyWith({
    String? id,
    String? title,
    TodoCategory? category,
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
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
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
    );
  }
}