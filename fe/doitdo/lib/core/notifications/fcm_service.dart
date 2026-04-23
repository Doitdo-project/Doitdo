import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:doitdo/core/utils/app_logger.dart';

class FcmService {
  FcmService._();

  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    await _local.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    await FirebaseMessaging.instance.requestPermission();

    // 개발 편의 — 디버그 빌드에서만 토큰을 로그로 노출해 테스트 푸시 보낼 때 사용.
    // 운영 빌드에선 서버에 등록하는 로직이 별도로 필요하다.
    if (kDebugMode) {
      try {
        final token = await FirebaseMessaging.instance.getToken();
        appLogger.i('[FCM] 디바이스 토큰: $token');
      } catch (e) {
        appLogger.w('[FCM] 토큰 조회 실패: $e');
      }
    }

    FirebaseMessaging.onMessage.listen(_handleForeground);
  }

  static Future<String?> getToken() => FirebaseMessaging.instance.getToken();

  static void _handleForeground(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _local.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'default_channel',
          '기본 알림',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
