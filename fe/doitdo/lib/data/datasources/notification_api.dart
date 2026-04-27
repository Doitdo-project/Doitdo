import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'package:doitdo/core/network/api_response.dart';
import 'package:doitdo/data/models/device_token_dto.dart';
import 'package:doitdo/data/models/notification_dto.dart';

part 'notification_api.g.dart';

@RestApi()
abstract class NotificationApi {
  factory NotificationApi(Dio dio, {String baseUrl}) = _NotificationApi;

  // [N02] FCM 디바이스 토큰 등록 (201 Created)
  @POST('/api/notifications/device-token')
  Future<ApiResponse<DeviceTokenResp>> registerDeviceToken(
    @Body() DeviceTokenRegisterReq body,
  );

  // [N03] FCM 디바이스 토큰 해제 (204 No Content)
  @DELETE('/api/notifications/device-token')
  Future<void> unregisterDeviceToken(
    @Body() DeviceTokenUnregisterReq body,
  );

  // [N04] 알림 목록 조회 (페이지네이션 + isRead 필터)
  @GET('/api/notifications')
  Future<ApiResponse<NotificationListResp>> getNotifications({
    @Query('isRead') bool? isRead,
    @Query('page') int? page,
    @Query('size') int? size,
  });

  // [N05] 단일 알림 읽음 처리
  @PATCH('/api/notifications/{notificationId}/read')
  Future<ApiResponse<NotificationReadResp>> markAsRead(
    @Path('notificationId') int notificationId,
  );

  // [N06] 전체 알림 읽음 처리
  @PATCH('/api/notifications/read-all')
  Future<ApiResponse<NotificationReadAllResp>> markAllAsRead();

  // [N07] 단일 알림 삭제 (소프트 삭제, 204 No Content)
  @DELETE('/api/notifications/{notificationId}')
  Future<void> deleteNotification(
    @Path('notificationId') int notificationId,
  );

  // [N08] 알림 전체 삭제 (소프트 삭제, 204 No Content)
  @DELETE('/api/notifications')
  Future<void> deleteAllNotifications();
}
