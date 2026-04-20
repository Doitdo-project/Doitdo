import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:doitdo/app.dart';
import 'package:doitdo/core/utils/app_env.dart';
import 'package:doitdo/presentation/providers/app_data_providers.dart';

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