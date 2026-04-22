import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:doitdo/app.dart';
import 'package:doitdo/core/utils/app_env.dart';
import 'package:doitdo/presentation/providers/app_data_providers.dart';

import 'package:intl/date_symbol_data_local.dart';
// NOTE: Firebase/FCM 초기화는 UI 작업이 끝나고 FCM 연동 단계에서 활성화한다.
// 활성화 방법:
//   1) `dart pub global activate flutterfire_cli`
//   2) 프로젝트 루트에서 `flutterfire configure` 실행
//      → lib/firebase_options.dart, android/app/google-services.json,
//        ios/Runner/GoogleService-Info.plist 가 자동 생성된다
//   3) 아래 주석 처리된 import와 try/catch 블록을 해제한다
// import 'package:firebase_core/firebase_core.dart';
// import 'package:doitdo/core/notifications/fcm_service.dart';
// import 'package:doitdo/core/utils/app_logger.dart';
// import 'package:doitdo/firebase_options.dart';

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

  // try {
  //   await Firebase.initializeApp(
  //     options: DefaultFirebaseOptions.currentPlatform,
  //   );
  //   await FcmService.init();
  // } catch (e) {
  //   appLogger.w('Firebase 초기화 실패: $e');
  // }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const DoitdoApp(),
    ),
  );
}