import 'package:dio/dio.dart';

import 'package:doitdo/core/network/logging_interceptor.dart';
import 'package:doitdo/core/utils/app_env.dart';

class ApiClient {
  ApiClient._();

  static Dio create() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppEnv.optional('API_BASE_URL'),
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    // 디버그 빌드에서만 요청/응답을 로그로 남긴다. 나머지 인터셉터(auth 등)는
    // `dioProvider` 에서 주입되므로 여기서는 로깅만 담당한다.
    dio.interceptors.add(const LoggingInterceptor());
    return dio;
  }
}
