import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:doitdo/core/utils/app_logger.dart';

/// 디버그 빌드에서만 요청/응답/에러를 `AppLogger` 로 찍는다.
///
/// 릴리즈 빌드에서는 성능/보안상 로그가 남지 않도록 `kDebugMode` 가드로 우회.
/// 토큰 등 민감 헤더는 마스킹해 찍는다.
class LoggingInterceptor extends Interceptor {
  const LoggingInterceptor();

  static const _maskedHeaderKeys = {'authorization', 'cookie'};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      appLogger.d(
        '→ ${options.method} ${options.uri}\n'
        'headers: ${_maskHeaders(options.headers)}\n'
        'body: ${options.data}',
      );
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      appLogger.d(
        '← ${response.statusCode} ${response.requestOptions.uri}\n'
        'body: ${response.data}',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      appLogger.w(
        '× ${err.requestOptions.method} ${err.requestOptions.uri}\n'
        'type: ${err.type}\n'
        'status: ${err.response?.statusCode}\n'
        'body: ${err.response?.data}',
      );
    }
    handler.next(err);
  }

  Map<String, dynamic> _maskHeaders(Map<String, dynamic> headers) {
    return {
      for (final entry in headers.entries)
        entry.key: _maskedHeaderKeys.contains(entry.key.toLowerCase())
            ? '***'
            : entry.value,
    };
  }
}