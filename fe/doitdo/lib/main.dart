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