/// 알림 API DTO.
///
/// swagger `/api/notifications` 스펙 기준:
/// - NotificationResp      : 단건 알림 항목
/// - NotificationListResp  : 페이지네이션 목록 { items, page, size, totalElements, totalPages }
/// - NotificationReadResp  : 읽음 처리 결과 { notificationId, isRead, readAt }
/// - NotificationReadAllResp: 전체 읽음 처리 결과 { updatedCount }

/// 서버 type enum 값 → 알림 유형.
///
/// 서버 swagger `NotificationResp.type` 와 일치:
/// REMINDER_EVENING / REMINDER_MORNING / REMINDER_STREAK_TODO_EMPTY /
/// TODO_DONE / TODO_REMINDER / TODO_SNOOZED /
/// TAMAGOTCHI_FAREWELL / TAMAGOTCHI_GROWTH
///
/// `unknown` 은 서버가 새 type 을 도입했을 때 안전 폴백.
enum NotificationTypeDto {
  reminderEvening,         // REMINDER_EVENING
  reminderMorning,         // REMINDER_MORNING
  reminderStreakTodoEmpty, // REMINDER_STREAK_TODO_EMPTY — 연속달성 todo 비어있을 때
  todoDone,                // TODO_DONE
  todoReminder,            // TODO_REMINDER
  todoSnoozed,             // TODO_SNOOZED
  tamagochiFarewell,       // TAMAGOTCHI_FAREWELL
  tamagochiGrowth,         // TAMAGOTCHI_GROWTH
  unknown,                 // 미래 type 안전 폴백
}

NotificationTypeDto _parseType(String raw) {
  switch (raw) {
    case 'REMINDER_EVENING':           return NotificationTypeDto.reminderEvening;
    case 'REMINDER_MORNING':           return NotificationTypeDto.reminderMorning;
    case 'REMINDER_STREAK_TODO_EMPTY': return NotificationTypeDto.reminderStreakTodoEmpty;
    case 'TODO_DONE':                  return NotificationTypeDto.todoDone;
    case 'TODO_REMINDER':              return NotificationTypeDto.todoReminder;
    case 'TODO_SNOOZED':               return NotificationTypeDto.todoSnoozed;
    case 'TAMAGOTCHI_FAREWELL':        return NotificationTypeDto.tamagochiFarewell;
    case 'TAMAGOTCHI_GROWTH':          return NotificationTypeDto.tamagochiGrowth;
    default:                           return NotificationTypeDto.unknown;
  }
}

class NotificationResp {
  const NotificationResp({
    required this.notificationId,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.referenceId,
    this.readAt,
  });

  final int notificationId;
  final NotificationTypeDto type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final int? referenceId;
  final DateTime? readAt;

  factory NotificationResp.fromJson(Map<String, dynamic> json) =>
      NotificationResp(
        notificationId: (json['notificationId'] as num).toInt(),
        type: _parseType(json['type'] as String),
        title: json['title'] as String,
        message: json['message'] as String,
        isRead: json['isRead'] as bool,
        createdAt: DateTime.parse(json['createdAt'] as String),
        referenceId: json['referenceId'] == null
            ? null
            : (json['referenceId'] as num).toInt(),
        readAt: json['readAt'] == null
            ? null
            : DateTime.parse(json['readAt'] as String),
      );
}

class NotificationListResp {
  const NotificationListResp({
    required this.items,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });

  final List<NotificationResp> items;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;

  factory NotificationListResp.fromJson(Map<String, dynamic> json) =>
      NotificationListResp(
        items: (json['items'] as List<dynamic>)
            .map((e) => NotificationResp.fromJson(e as Map<String, dynamic>))
            .toList(),
        page: (json['page'] as num).toInt(),
        size: (json['size'] as num).toInt(),
        totalElements: (json['totalElements'] as num).toInt(),
        totalPages: (json['totalPages'] as num).toInt(),
      );
}

class NotificationReadResp {
  const NotificationReadResp({
    required this.notificationId,
    required this.isRead,
    this.readAt,
  });

  final int notificationId;
  final bool isRead;
  final DateTime? readAt;

  factory NotificationReadResp.fromJson(Map<String, dynamic> json) =>
      NotificationReadResp(
        notificationId: (json['notificationId'] as num).toInt(),
        isRead: json['isRead'] as bool,
        readAt: json['readAt'] == null
            ? null
            : DateTime.parse(json['readAt'] as String),
      );
}

class NotificationReadAllResp {
  const NotificationReadAllResp({required this.updatedCount});

  final int updatedCount;

  factory NotificationReadAllResp.fromJson(Map<String, dynamic> json) =>
      NotificationReadAllResp(
        updatedCount: (json['updatedCount'] as num).toInt(),
      );
}
