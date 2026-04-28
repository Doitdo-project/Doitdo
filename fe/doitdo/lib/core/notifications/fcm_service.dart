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
        // iOS: firebase_messaging 의 requestPermission 과 별개로 flutter_local_notifications
        // 자체의 권한도 명시적으로 요청. 둘이 다른 모듈을 통해 권한을 따로 받기 때문에
        // 한쪽만 호출하면 silent 알림처럼 보이는 케이스가 있다.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        ),
      ),
    );

    // 시스템 알림 권한 요청. 결과를 로깅해 디버깅 용이성 확보.
    final settings = await FirebaseMessaging.instance.requestPermission();
    appLogger.i(
      '[FCM] 알림 권한 상태: ${settings.authorizationStatus.name} '
      '(alert=${settings.alert.name}, badge=${settings.badge.name}, sound=${settings.sound.name})',
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      appLogger.w(
        '[FCM] 알림 권한 DENIED — iOS 설정에서 직접 켜지 않으면 푸시가 도착해도 표시되지 않는다',
      );
    }

    // iOS 에서 앱이 포어그라운드일 때도 시스템 배너/사운드/배지가 뜨도록.
    // 이 옵션을 안 주면 앱이 켜진 동안 들어온 푸시는 표시되지 않는다.
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

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

  /// 디버그 진단 — APNs 토큰 / FCM 토큰 / 권한 상태를 한 번에 로그.
  /// 실기에서 알림이 안 오는 원인을 좁힐 때 호출.
  static Future<void> logDiagnostics() async {
    try {
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      appLogger.i(
        '[FCM diag] auth=${settings.authorizationStatus.name} '
        'alert=${settings.alert.name} badge=${settings.badge.name} sound=${settings.sound.name}',
      );
    } catch (e) {
      appLogger.w('[FCM diag] settings 조회 실패: $e');
    }
    try {
      final apns = await FirebaseMessaging.instance.getAPNSToken();
      appLogger.i('[FCM diag] APNs token=${apns ?? "null"}');
    } catch (e) {
      appLogger.w('[FCM diag] APNs token 조회 실패: $e');
    }
    try {
      final fcm = await FirebaseMessaging.instance.getToken();
      appLogger.i('[FCM diag] FCM token=${fcm ?? "null"}');
    } catch (e) {
      appLogger.w('[FCM diag] FCM token 조회 실패: $e');
    }
  }

  static const _blockedTypes = {
    'TODO_DONE',
    'TODO_SNOOZED',
    'TAMAGOTCHI_GROWTH',
  };

  static void _handleForeground(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    final type = message.data['type'] as String?;
    if (type != null && _blockedTypes.contains(type)) return;

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
