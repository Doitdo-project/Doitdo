import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:doitdo/core/config/app_config.dart';
import 'package:doitdo/core/network/api_client.dart';
import 'package:doitdo/core/network/auth_interceptor.dart';
import 'package:doitdo/core/notifications/fcm_token_registrar.dart';
import 'package:doitdo/core/utils/app_env.dart';
import 'package:doitdo/core/widget_sync/widget_sync_service.dart';
import 'package:doitdo/data/datasources/auth_api.dart';
import 'package:doitdo/data/datasources/auth_local_data_source.dart';
import 'package:doitdo/data/datasources/bug_report_api.dart';
import 'package:doitdo/data/datasources/user_api.dart';
import 'package:doitdo/data/repositories/auth_repository_impl.dart';
import 'package:doitdo/data/repositories/bug_report_repository_impl.dart';
import 'package:doitdo/data/repositories/user_repository_impl.dart';
import 'package:doitdo/domain/repositories/auth_repository.dart';
import 'package:doitdo/domain/repositories/bug_report_repository.dart';
import 'package:doitdo/domain/repositories/user_repository.dart';
import 'package:doitdo/data/datasources/todo_api.dart';
import 'package:doitdo/data/repositories/todo_repository_impl.dart';
import 'package:doitdo/domain/repositories/todo_repository.dart';
import 'package:doitdo/data/datasources/category_api.dart';
import 'package:doitdo/data/datasources/character_api.dart';
import 'package:doitdo/data/datasources/notification_api.dart';
import 'package:doitdo/data/datasources/setting_api.dart';
import 'package:doitdo/data/datasources/shop_api.dart';
import 'package:doitdo/data/datasources/streak_api.dart';
import 'package:doitdo/data/repositories/category_repository_impl.dart';
import 'package:doitdo/data/repositories/character_repository_impl.dart';
import 'package:doitdo/data/repositories/notification_repository_impl.dart';
import 'package:doitdo/data/repositories/setting_repository_impl.dart';
import 'package:doitdo/data/repositories/shop_repository_impl.dart';
import 'package:doitdo/data/repositories/streak_repository_impl.dart';
import 'package:doitdo/domain/repositories/category_repository.dart';
import 'package:doitdo/domain/repositories/character_repository.dart';
import 'package:doitdo/domain/repositories/notification_repository.dart';
import 'package:doitdo/domain/repositories/setting_repository.dart';
import 'package:doitdo/domain/repositories/shop_repository.dart';
import 'package:doitdo/domain/repositories/streak_repository.dart';

// 중앙 집중식 DI 선언 파일 (MOA 컨벤션)
// datasource → repository → service 순서로 Provider 추가.

// ─── 외부 인프라 ────────────────────────────────────────────────

final dioProvider = Provider<Dio>((ref) {
  final dio = ApiClient.create();
  final storage = ref.watch(secureStorageProvider);
  final widgetSync = ref.watch(widgetSyncServiceProvider);
  // Bearer 토큰 주입 + 401 자동 refresh 재시도는 AuthInterceptor 에 일임.
  // refresh 성공 시 위젯 SharedPreferences 도 동기화 — 인터셉터가 갱신한 토큰이
  // 위젯에 전달되지 않으면 위젯이 만료된 refresh token 으로 재시도해 로그인 필요 상태가 됨.
  dio.interceptors.add(AuthInterceptor(
    dio: dio,
    storage: storage,
    onTokenRefreshed: (access, refresh) {
      widgetSync.syncAuthTokens(
        accessToken: access,
        refreshToken: refresh,
        apiBaseUrl: AppConfig.apiBaseUrl,
      );
    },
  ));
  return dio;
});

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('main.dart 에서 override 로 주입되어야 합니다.');
});

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  ),
);

// ─── OAuth 클라이언트 ───────────────────────────────────────────
final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  // Web Server Client ID.
  // .env 의 GOOGLE_SERVER_CLIENT_ID 에서 로드.
  // 백엔드가 ID Token 의 aud 를 이 값으로 검증하므로 프론트/백 양쪽이 동일해야 한다.
  final serverClientId = AppEnv.optional('GOOGLE_SERVER_CLIENT_ID');
  return GoogleSignIn(
    scopes: const ['email', 'profile'],
    serverClientId: serverClientId.isNotEmpty ? serverClientId : null,
  );
});

// ─── Retrofit API ──────────────────────────────────────────────
final authApiProvider = Provider<AuthApi>(
  (ref) => AuthApi(ref.watch(dioProvider)),
);

final userApiProvider = Provider<UserApi>(
  (ref) => UserApi(ref.watch(dioProvider)),
);

// ─── Auth: Local DataSource ────────────────────────────────────
final authLocalDataSourceProvider = Provider<AuthLocalDataSource>(
  (ref) => AuthLocalDataSource(ref.watch(secureStorageProvider)),
);

// ─── 홈스크린 위젯 동기화 ────────────────────────────────────────
// 앱 ↔ iOS 위젯 extension / Android AppWidget Provider 간 데이터 다리.
// AuthRepository / TodoRepository 변경 지점에서 주입받아 호출하므로 여기 단일 인스턴스 등록.
final widgetSyncServiceProvider = Provider<WidgetSyncService>(
  (ref) => WidgetSyncService(),
);

// ─── Repository ────────────────────────────────────────────────
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    authApi: ref.watch(authApiProvider),
    local: ref.watch(authLocalDataSourceProvider),
    googleSignIn: ref.watch(googleSignInProvider),
    widgetSync: ref.watch(widgetSyncServiceProvider),
    apiBaseUrl: AppConfig.apiBaseUrl,
  ),
);

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepositoryImpl(ref.watch(userApiProvider)),
);

// ─── Todo: retrofit API → Repository ───────────────────────────
final todoApiProvider = Provider<TodoApi>(
      (ref) => TodoApi(ref.watch(dioProvider)), // 진짜 서버 주소와 토큰이 들어간 dio 적용
);

final todoRepositoryProvider = Provider<TodoRepository>(
      (ref) => TodoRepositoryImpl(ref.watch(todoApiProvider)),
);

// ─── Category: retrofit API → Repository ───────────────────────
final categoryApiProvider = Provider<CategoryApi>(
  (ref) => CategoryApi(ref.watch(dioProvider)),
);

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => CategoryRepositoryImpl(ref.watch(categoryApiProvider)),
);

// ─── Setting: retrofit API → Repository ────────────────────────
final settingApiProvider = Provider<SettingApi>(
  (ref) => SettingApi(ref.watch(dioProvider)),
);

final settingRepositoryProvider = Provider<SettingRepository>(
  (ref) => SettingRepositoryImpl(ref.watch(settingApiProvider)),
);

// ─── Character: retrofit API → Repository ──────────────────────
final characterApiProvider = Provider<CharacterApi>(
  (ref) => CharacterApi(ref.watch(dioProvider)),
);

final characterRepositoryProvider = Provider<CharacterRepository>(
  (ref) => CharacterRepositoryImpl(ref.watch(characterApiProvider)),
);

// ─── Notification: retrofit API → Repository ───────────────────
final notificationApiProvider = Provider<NotificationApi>(
  (ref) => NotificationApi(ref.watch(dioProvider)),
);

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepositoryImpl(ref.watch(notificationApiProvider)),
);

// ─── Streak: retrofit API → Repository ─────────────────────────
final streakApiProvider = Provider<StreakApi>(
  (ref) => StreakApi(ref.watch(dioProvider)),
);

final streakRepositoryProvider = Provider<StreakRepository>(
  (ref) => StreakRepositoryImpl(ref.watch(streakApiProvider)),
);

// ─── Shop: retrofit API → Repository ───────────────────────────
// 상점 / 보유 가구 / 방 배치 통합 도메인.
final shopApiProvider = Provider<ShopApi>(
  (ref) => ShopApi(ref.watch(dioProvider)),
);

final shopRepositoryProvider = Provider<ShopRepository>(
  (ref) => ShopRepositoryImpl(ref.watch(shopApiProvider)),
);

// ─── BugReport: retrofit API → Repository ──────────────────────
final bugReportApiProvider = Provider<BugReportApi>(
  (ref) => BugReportApi(ref.watch(dioProvider)),
);

final bugReportRepositoryProvider = Provider<BugReportRepository>(
  (ref) => BugReportRepositoryImpl(ref.watch(bugReportApiProvider)),
);

// ─── FCM: 디바이스 토큰 등록 헬퍼 ───────────────────────────────
// 앱 전체에서 1개 인스턴스만 필요 (onTokenRefresh listener 중복 방지).
// 로그인 성공 시 register(), 로그아웃 직전 unregister() 호출.
final fcmTokenRegistrarProvider = Provider<FcmTokenRegistrar>(
  (ref) => FcmTokenRegistrar(ref.watch(notificationRepositoryProvider)),
);
