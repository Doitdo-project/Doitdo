import 'package:doitdo/core/network/base_repository.dart';
import 'package:doitdo/data/datasources/notification_api.dart';
import 'package:doitdo/data/models/device_token_dto.dart';
import 'package:doitdo/data/models/notification_dto.dart';
import 'package:doitdo/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl extends BaseRepository
    implements NotificationRepository {
  NotificationRepositoryImpl(this._api);

  final NotificationApi _api;

  @override
  Future<DeviceTokenResp> registerDeviceToken({
    required String fcmToken,
    required DeviceTokenPlatform platform,
  }) =>
      safeApiCall(
        () => _api.registerDeviceToken(
          DeviceTokenRegisterReq(fcmToken: fcmToken, platform: platform),
        ),
      );

  @override
  Future<void> unregisterDeviceToken(String fcmToken) => safeApiCallVoid(
        () => _api.unregisterDeviceToken(
          DeviceTokenUnregisterReq(fcmToken: fcmToken),
        ),
      );

  @override
  Future<NotificationListResp> getNotifications({
    bool? isRead,
    int page = 0,
    int size = 20,
  }) =>
      safeApiCall(
        () => _api.getNotifications(isRead: isRead, page: page, size: size),
      );

  @override
  Future<NotificationReadResp> markAsRead(int notificationId) =>
      safeApiCall(() => _api.markAsRead(notificationId));

  @override
  Future<NotificationReadAllResp> markAllAsRead() =>
      safeApiCall(() => _api.markAllAsRead());

  @override
  Future<void> deleteNotification(int notificationId) =>
      safeApiCallVoid(() => _api.deleteNotification(notificationId));
}
