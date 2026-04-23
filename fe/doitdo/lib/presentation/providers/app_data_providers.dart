import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:doitdo/core/network/api_client.dart';
import 'package:doitdo/core/utils/app_env.dart';
import 'package:doitdo/data/datasources/auth_local_data_source.dart';
import 'package:doitdo/data/datasources/auth_remote_data_source.dart';
import 'package:doitdo/data/datasources/user_api.dart';
import 'package:doitdo/data/repositories/auth_repository_impl.dart';
import 'package:doitdo/data/repositories/user_repository_impl.dart';
import 'package:doitdo/domain/repositories/auth_repository.dart';
import 'package:doitdo/domain/repositories/user_repository.dart';
import 'package:doitdo/data/datasources/todo_api.dart';
import 'package:doitdo/data/repositories/todo_repository_impl.dart';
import 'package:doitdo/domain/repositories/todo_repository.dart';

// 중앙 집중식 DI 선언 파일 (MOA 컨벤션)
// datasource → repository → service 순서로 Provider 추가.

// ─── 외부 인프라 ────────────────────────────────────────────────
final dioProvider = Provider<Dio>((ref) {
  final dio = ApiClient.create();
  // secure storage 에 저장된 access token 을 자동으로 Authorization 헤더에 부착.
  // 인증 엔드포인트(/api/auth/*) 는 제외.
  final storage = ref.watch(secureStorageProvider);
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      if (!options.path.contains('/auth/')) {
        final token = await storage.read(key: 'auth_access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      }
      handler.next(options);
    },
    // TODO: onError 에서 401 받으면 refresh token 으로 재발급 시도 로직 추가.
    //       refresh 엔드포인트 스펙 확정되면 구현.
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

// ─── Auth: DataSource → Repository ─────────────────────────────
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSource(ref.watch(dioProvider)),
);

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>(
  (ref) => AuthLocalDataSource(ref.watch(secureStorageProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    remote: ref.watch(authRemoteDataSourceProvider),
    local: ref.watch(authLocalDataSourceProvider),
    googleSignIn: ref.watch(googleSignInProvider),
  ),
);

// ─── User: retrofit API → Repository ───────────────────────────
// retrofit 기반 모듈의 레퍼런스 구현. 새 도메인 추가 시 이 2 Provider 쌍을
// 복제해서 쓰면 된다. (datasource → repository 순)
final userApiProvider = Provider<UserApi>(
  (ref) => UserApi(ref.watch(dioProvider)),
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
