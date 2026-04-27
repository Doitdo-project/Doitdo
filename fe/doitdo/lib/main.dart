import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:doitdo/app.dart';
import 'package:doitdo/core/notifications/fcm_service.dart';
import 'package:doitdo/core/utils/app_env.dart';
import 'package:doitdo/core/utils/app_logger.dart';
import 'package:doitdo/core/widget_sync/widget_sync_service.dart';
import 'package:doitdo/firebase_options.dart';
import 'package:doitdo/presentation/providers/app_data_providers.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// 앱이 백그라운드/종료 상태일 때 도착하는 FCM 메시지 처리.
///
/// - 반드시 top-level (혹은 static) 함수여야 한다 — Flutter engine 이 별도 isolate
///   에서 호출하기 때문에 클로저/인스턴스 메서드는 사용할 수 없다.
/// - `@pragma('vm:entry-point')` 는 release 빌드에서 tree-shake 으로 제거되지 않도록.
/// - 현재는 로깅만. 추후 배지 카운트 갱신, 위젯 sync 등 필요한 부수효과를 여기에 추가.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  // 백그라운드 isolate 라 appLogger 가 초기화 안 돼 있을 수 있어 print 로 둔다.
  // ignore: avoid_print
  print('[FCM bg] received messageId=${message.messageId} '
      'title=${message.notification?.title}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppEnv.load();
  await initializeDateFormatting('ko_KR', null);

  // Kakao SDK 는 앱 기동 시 한 번만 초기화해야 한다.
  // 네이티브 앱 키가 비어있으면 init 을 건너뛴다 — 개발자가 .env 설정 전에도 앱이 기동되도록.
  // 실제 Kakao 로그인 호출 시점엔 키 없으면 SDK 가 예외 throw 함.
  final kakaoKey = AppEnv.optional('KAKAO_NATIVE_APP_KEY');
  if (kakaoKey.isNotEmpty) {
    KakaoSdk.init(nativeAppKey: kakaoKey);
  }

  await Hive.initFlutter();
  final prefs = await SharedPreferences.getInstance();

  // 홈스크린 위젯 ↔ 앱 공유 저장소 초기화 (iOS App Group / Android SharedPreferences).
  // 위젯 native 코드가 같은 App Group ID 로 데이터를 읽기 때문에 앱 시작 직후 1회 set 필요.
  // 실패해도 앱은 정상 기동 — 위젯이 동작 안 할 뿐.
  await WidgetSyncService().init();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // 백그라운드 핸들러는 Firebase init 직후, FCM 다른 호출보다 먼저 등록해야 한다.
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
    await FcmService.init();
  } catch (e) {
    appLogger.w('Firebase 초기화 실패: $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const DoitdoApp(),
    ),
  );
}