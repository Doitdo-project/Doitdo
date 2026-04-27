import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/core/utils/app_logger.dart';
import 'package:doitdo/data/models/notification_dto.dart';
import 'package:doitdo/domain/repositories/notification_repository.dart';
import 'package:doitdo/presentation/providers/app_data_providers.dart';

// ─────────────────────────────────────────────
// 알림 유형 (서버 enum → 앱 내부 enum)
//
// 서버 type 은 7종 (swagger 기준):
//   REMINDER_EVENING / REMINDER_MORNING
//   TODO_DONE / TODO_REMINDER / TODO_SNOOZED
//   TAMAGOTCHI_FAREWELL / TAMAGOTCHI_GROWTH
// ─────────────────────────────────────────────
enum NotificationType {
  evening,            // REMINDER_EVENING
  morning,            // REMINDER_MORNING
  todoDone,           // TODO_DONE
  todoReminder,       // TODO_REMINDER
  todoSnoozed,        // TODO_SNOOZED
  tamagochiFarewell,  // TAMAGOTCHI_FAREWELL
  tamagochiGrowth,    // TAMAGOTCHI_GROWTH
  unknown,            // 미래 type 안전 폴백
}

extension NotificationTypeX on NotificationType {
  String get label {
    switch (this) {
      case NotificationType.evening:            return '저녁 회고';
      case NotificationType.morning:            return '아침 리마인드';
      case NotificationType.todoDone:           return '할 일 완료';
      case NotificationType.todoReminder:       return '할 일 알림';
      case NotificationType.todoSnoozed:        return '할 일 미루기';
      case NotificationType.tamagochiFarewell:  return '작별 인사';
      case NotificationType.tamagochiGrowth:    return '다마고치 성장';
      case NotificationType.unknown:            return '알림';
    }
  }

  /// 화면 필터(NotiFilter.todoTask) 에 묶일 "할 일" 카테고리 여부.
  bool get isTodoCategory =>
      this == NotificationType.todoDone ||
      this == NotificationType.todoReminder ||
      this == NotificationType.todoSnoozed;
}

NotificationType _toAppType(NotificationTypeDto dto) {
  switch (dto) {
    case NotificationTypeDto.reminderEvening:   return NotificationType.evening;
    case NotificationTypeDto.reminderMorning:   return NotificationType.morning;
    case NotificationTypeDto.todoDone:          return NotificationType.todoDone;
    case NotificationTypeDto.todoReminder:      return NotificationType.todoReminder;
    case NotificationTypeDto.todoSnoozed:       return NotificationType.todoSnoozed;
    case NotificationTypeDto.tamagochiFarewell: return NotificationType.tamagochiFarewell;
    case NotificationTypeDto.tamagochiGrowth:   return NotificationType.tamagochiGrowth;
    case NotificationTypeDto.unknown:           return NotificationType.unknown;
  }
}

// ─────────────────────────────────────────────
// 앱 내부 알림 아이템 모델 (DTO → UI 모델 변환)
// ─────────────────────────────────────────────
class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.isRead,
  });

  final int id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;

  NotificationItem copyWith({bool? isRead}) => NotificationItem(
    id: id,
    type: type,
    title: title,
    message: message,
    createdAt: createdAt,
    isRead: isRead ?? this.isRead,
  );

  factory NotificationItem.fromDto(NotificationResp dto) => NotificationItem(
    id: dto.notificationId,
    type: _toAppType(dto.type),
    title: dto.title,
    message: dto.message,
    createdAt: dto.createdAt,
    isRead: dto.isRead,
  );
}

// ─────────────────────────────────────────────
// 필터 칩 enum
// "할 일" 필터는 todoDone / todoReminder / todoSnoozed 3종을 묶어 표시.
// ─────────────────────────────────────────────
enum NotiFilter {
  all,      // 전체
  unread,   // 안 읽음
  evening,  // 저녁
  morning,  // 아침
  todoTask, // 할 일 (TODO_DONE + TODO_REMINDER + TODO_SNOOZED)
}

extension NotiFilterX on NotiFilter {
  String get label {
    switch (this) {
      case NotiFilter.all:      return '전체';
      case NotiFilter.unread:   return '안 읽음';
      case NotiFilter.evening:  return '저녁';
      case NotiFilter.morning:  return '아침';
      case NotiFilter.todoTask: return '할 일';
    }
  }
}

// ─────────────────────────────────────────────
// 상태
// ─────────────────────────────────────────────
class NotificationState {
  const NotificationState({
    required this.items,
    required this.filter,
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 0,
    this.errorMessage,
  });

  final List<NotificationItem> items;
  final NotiFilter filter;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? errorMessage;

  List<NotificationItem> get filtered {
    switch (filter) {
      case NotiFilter.all:
        return items;
      case NotiFilter.unread:
        return items.where((n) => !n.isRead).toList();
      case NotiFilter.evening:
        return items.where((n) => n.type == NotificationType.evening).toList();
      case NotiFilter.morning:
        return items.where((n) => n.type == NotificationType.morning).toList();
      case NotiFilter.todoTask:
        return items.where((n) => n.type.isTodoCategory).toList();
    }
  }

  int get unreadCount => items.where((n) => !n.isRead).length;

  NotificationState copyWith({
    List<NotificationItem>? items,
    NotiFilter? filter,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? errorMessage,
  }) =>
      NotificationState(
        items: items ?? this.items,
        filter: filter ?? this.filter,
        isLoading: isLoading ?? this.isLoading,
        hasMore: hasMore ?? this.hasMore,
        currentPage: currentPage ?? this.currentPage,
        errorMessage: errorMessage,
      );
}

// ─────────────────────────────────────────────
// ViewModel
// ─────────────────────────────────────────────
class NotificationViewModel extends StateNotifier<NotificationState> {
  NotificationViewModel(this._repo)
      : super(const NotificationState(items: [], filter: NotiFilter.all)) {
    _load(refresh: true);
  }

  final NotificationRepository _repo;

  static const _pageSize = 20;

  /// 목록 로드. [refresh]=true면 1페이지부터 다시 로드.
  Future<void> _load({bool refresh = false}) async {
    if (state.isLoading) return;
    if (!refresh && !state.hasMore) return;

    final page = refresh ? 0 : state.currentPage;
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final resp = await _repo.getNotifications(page: page, size: _pageSize);
      // 디버그 로그 — Swagger 에서는 목록이 보이는데 앱에서 빈 화면이 뜨는
      // 케이스를 추적하기 위해 응답 요약을 찍어둔다. 문제 해결되면 삭제 가능.
      appLogger.i(
        '[Notification] page=$page size=$_pageSize '
        'items=${resp.items.length} totalElements=${resp.totalElements} '
        'totalPages=${resp.totalPages}',
      );
      final newItems = resp.items.map(NotificationItem.fromDto).toList();

      state = state.copyWith(
        items: refresh ? newItems : [...state.items, ...newItems],
        isLoading: false,
        currentPage: resp.page + 1,
        hasMore: resp.page + 1 < resp.totalPages,
      );
    } catch (e, st) {
      // 이전엔 errorMessage 만 세팅하고 silent fail — 빈 화면과 에러 화면의
      // 구분이 안 돼서 로그/스택트레이스까지 남긴다.
      appLogger.e('[Notification] 목록 로드 실패', error: e, stackTrace: st);
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// 다음 페이지 로드 (무한 스크롤용)
  Future<void> loadMore() => _load(refresh: false);

  /// 새로고침
  Future<void> refresh() => _load(refresh: true);

  /// 필터 변경
  void setFilter(NotiFilter filter) {
    state = state.copyWith(filter: filter);
  }

  /// 단일 알림 읽음 처리
  Future<void> markAsRead(int notificationId) async {
    // 낙관적 UI 업데이트: 서버 응답 전에 로컬 상태 먼저 변경.
    state = state.copyWith(
      items: state.items
          .map((n) => n.id == notificationId ? n.copyWith(isRead: true) : n)
          .toList(),
    );
    try {
      await _repo.markAsRead(notificationId);
    } catch (_) {
      // 실패 시 롤백
      state = state.copyWith(
        items: state.items
            .map((n) => n.id == notificationId ? n.copyWith(isRead: false) : n)
            .toList(),
      );
    }
  }

  /// 전체 알림 읽음 처리
  Future<void> markAllAsRead() async {
    final prev = state.items;
    // 낙관적 UI 업데이트
    state = state.copyWith(
      items: state.items.map((n) => n.copyWith(isRead: true)).toList(),
    );
    try {
      await _repo.markAllAsRead();
    } catch (_) {
      // 실패 시 롤백
      state = state.copyWith(items: prev);
    }
  }

  /// 단일 알림 삭제 후 목록에서 제거
  Future<void> deleteNotification(int notificationId) async {
    final prev = state.items;
    state = state.copyWith(
      items: state.items.where((n) => n.id != notificationId).toList(),
    );
    try {
      await _repo.deleteNotification(notificationId);
    } catch (_) {
      state = state.copyWith(items: prev);
    }
  }
}

final notificationViewModelProvider =
    StateNotifierProvider.autoDispose<NotificationViewModel, NotificationState>(
  (ref) => NotificationViewModel(ref.watch(notificationRepositoryProvider)),
);
