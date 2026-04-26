import 'package:doitdo/data/models/device_token_dto.dart';
import 'package:doitdo/data/models/notification_dto.dart';

abstract class NotificationRepository {
  /// FCM 디바이스 토큰 등록. 로그인 직후/토큰 refresh 시 호출.
  Future<DeviceTokenResp> registerDeviceToken({
    required String fcmToken,
    required DeviceTokenPlatform platform,
  });

  /// FCM 디바이스 토큰 해제. 로그아웃 직전에 호출.
  Future<void> unregisterDeviceToken(String fcmToken);

  /// 알림 목록 조회 (페이지네이션).
  /// [isRead] null이면 전체, true/false이면 읽음/미읽음 필터.
  Future<NotificationListResp> getNotifications({
    bool? isRead,
    int page = 0,
    int size = 20,
  });

  /// 단일 알림 읽음 처리.
  Future<NotificationReadResp> markAsRead(int notificationId);

  /// 전체 알림 읽음 처리.
  Future<NotificationReadAllResp> markAllAsRead();

  /// 단일 알림 삭제 (소프트 삭제).
  Future<void> deleteNotification(int notificationId);
}
