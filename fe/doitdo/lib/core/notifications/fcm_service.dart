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

    FirebaseMessaging.onMessage.listen(_handleForeground);

    // 개발 편의 — 디버그 빌드에서는 FCM 토큰을 로그로 노출해 테스트 푸시 보낼 때 사용.
    // 릴리즈 빌드에서는 보안상 출력하지 않는다.
    if (kDebugMode) {
      final token = await FirebaseMessaging.instance.getToken();
      appLogger.i('[FCM] 디바이스 토큰: $token');
    }
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
