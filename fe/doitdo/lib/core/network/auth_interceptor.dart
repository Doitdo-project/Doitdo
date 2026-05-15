import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:doitdo/core/utils/app_logger.dart';

/// Bearer 토큰 주입 + 401 자동 refresh 재시도 인터셉터.
///
/// ### onRequest
/// 인증이 필요한 path 에 `Authorization: Bearer <access>` 헤더 추가.
/// 로그인·회원가입·refresh·중복체크·소셜 로그인 경로는 **건너뜀**.
/// 로그아웃(DELETE /api/auth/logout) 은 Bearer 필요라 제외 대상 아님.
///
/// ### onError
/// 401 응답 시:
/// 1. 이미 재시도된 요청이면 포기 (무한 루프 방지).
/// 2. refresh 자체가 401 이면 포기 (세션 완전 만료).
/// 3. refresh token 으로 `POST /api/auth/refresh` 호출 → 새 토큰 쌍 저장 →
///    원 요청을 새 토큰으로 재실행해서 사용자 모르게 이어간다.
/// 4. refresh 실패 시 로컬 토큰 삭제 + 원 에러 그대로 전파 (ViewModel 에서
///    `UnauthorizedException` 로 받아 로그인 화면으로 튕기는 건 후속 과제).
///
/// ### 동시 요청 안전성
/// 여러 요청이 동시에 401 을 받아도 refresh 는 **한 번만** 호출한다.
/// [Completer] 로 진행 중 refresh 결과를 공유.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.dio,
    required this.storage,
    this.onTokenRefreshed,
  });

  final Dio dio;
  final FlutterSecureStorage storage;

  /// refresh 성공 시 새 토큰 쌍을 외부(위젯 동기화 등)에 전달하는 콜백.
  final void Function(String accessToken, String refreshToken)? onTokenRefreshed;

  static const _kAccess = 'auth_access_token';
  static const _kRefresh = 'auth_refresh_token';

  /// 인증 헤더 주입을 건너뛸 경로들.
  /// 비밀번호 재설정 3단계는 모두 로그인 전에 호출되므로 access token 없이 보낸다.
  static const _unauthenticatedPaths = <String>{
    '/api/auth/login',
    '/api/auth/signup',
    '/api/auth/refresh',
    '/api/auth/password/reset-request',
    '/api/auth/password/reset/verify-code',
    '/api/auth/password/reset',
    '/api/users/check-email',
    '/api/users/check-username',
  };

  bool _shouldSkipAuth(String path) {
    if (_unauthenticatedPaths.contains(path)) return true;
    if (path.startsWith('/api/auth/social/')) return true;
    return false;
  }

  Completer<bool>? _refreshCompleter;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_shouldSkipAuth(options.path)) {
      final token = await storage.read(key: _kAccess);
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    final path = err.requestOptions.path;

    // 401 아니거나, 인증 불필요 경로거나, 이미 재시도된 요청이면 그대로.
    if (status != 401 ||
        _shouldSkipAuth(path) ||
        err.requestOptions.extra['_retried'] == true) {
      return handler.next(err);
    }

    try {
      final refreshed = await _refreshIfNeeded();
      if (!refreshed) {
        // refresh 실패 → 세션 종료. 토큰 삭제 후 원 에러 propagate.
        await _clearTokens();
        return handler.next(err);
      }
      // 새 토큰으로 원 요청 재실행. `_retried` 마킹해 무한루프 차단.
      final newToken = await storage.read(key: _kAccess);
      final retryOptions = Options(
        method: err.requestOptions.method,
        headers: {
          ...err.requestOptions.headers,
          'Authorization': 'Bearer $newToken',
        },
        extra: {...err.requestOptions.extra, '_retried': true},
        contentType: err.requestOptions.contentType,
        responseType: err.requestOptions.responseType,
      );
      final response = await dio.request<dynamic>(
        err.requestOptions.path,
        data: err.requestOptions.data,
        queryParameters: err.requestOptions.queryParameters,
        options: retryOptions,
      );
      return handler.resolve(response);
    } catch (e, st) {
      appLogger.e('refresh 재시도 실패', error: e, stackTrace: st);
      return handler.next(err);
    }
  }

  /// refresh 토큰으로 새 access/refresh 쌍을 받아 저장. 성공 여부 반환.
  /// 이미 진행 중이면 해당 Future 를 공유해서 중복 refresh 방지.
  Future<bool> _refreshIfNeeded() async {
    final ongoing = _refreshCompleter;
    if (ongoing != null) return ongoing.future;

    final completer = Completer<bool>();
    _refreshCompleter = completer;
    try {
      final refreshToken = await storage.read(key: _kRefresh);
      if (refreshToken == null) {
        completer.complete(false);
        return false;
      }
      // refresh 요청은 이 인터셉터가 붙지 않은 "순수한" 일회용 Dio 로 호출해,
      // 헤더 재주입 / 재귀 재시도 / 로깅 인터셉터 루프를 원천 차단.
      final freshDio = Dio(BaseOptions(baseUrl: dio.options.baseUrl));
      final response = await freshDio.post<Map<String, dynamic>>(
        '/api/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        completer.complete(false);
        return false;
      }
      final newAccess = data['accessToken'];
      final newRefresh = data['refreshToken'];
      if (newAccess is! String || newRefresh is! String) {
        completer.complete(false);
        return false;
      }
      await storage.write(key: _kAccess, value: newAccess);
      await storage.write(key: _kRefresh, value: newRefresh);
      onTokenRefreshed?.call(newAccess, newRefresh);
      completer.complete(true);
      return true;
    } catch (_) {
      completer.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<void> _clearTokens() async {
    await storage.delete(key: _kAccess);
    await storage.delete(key: _kRefresh);
  }
}
