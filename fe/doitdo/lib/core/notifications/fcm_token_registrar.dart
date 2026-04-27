import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:doitdo/core/utils/app_logger.dart';
import 'package:doitdo/data/models/device_token_dto.dart';
import 'package:doitdo/domain/repositories/notification_repository.dart';

/// FCM 디바이스 토큰을 서버에 등록/해제하는 얇은 헬퍼.
///
/// - 로그인 성공 직후 [register] 호출 → 현재 기기의 FCM 토큰을 서버에 POST
/// - Firebase 가 토큰을 회전(`onTokenRefresh`) 하면 자동으로 재등록
/// - 로그아웃 직전 [unregister] 호출 → 해당 FCM 토큰을 서버에서 비활성화
///
/// 실패는 모두 warn 로그로 흘리고 **상위에 throw 하지 않는다.** 푸시 등록은
/// 로그인/로그아웃 성공 여부를 좌우할 만큼 중요한 부수효과가 아니기 때문.
///
/// iOS 의 APNs race:
///   `FirebaseMessaging.getToken()` 은 APNs 토큰이 먼저 set 돼 있어야 정상 반환된다.
///   첫 설치/첫 로그인 직후엔 APNs 등록 콜백이 늦어 `getToken()` 이 null 을 돌려주는
///   케이스가 잦다. 그래서 iOS 에서는:
///     1) `onTokenRefresh` listener 를 **getToken 시도 전에** 먼저 부착해두고
///        (첫 시도가 실패해도 토큰이 도착하는 순간 자동 등록되도록)
///     2) `getAPNSToken()` 을 짧은 간격으로 polling 하며 도착을 기다린 뒤
///     3) `getToken()` 을 (필요 시 retry 와 함께) 호출한다.
///   Android 는 이 분기를 타지 않는다 — `getToken()` 이 즉시 정상 반환.
class FcmTokenRegistrar {
  FcmTokenRegistrar(this._repo);

  final NotificationRepository _repo;

  /// onTokenRefresh 구독은 앱 생명주기 동안 1번만 건다. register 가 여러 번
  /// 호출되더라도 listener 가 중복으로 등록되지 않도록 플래그로 가드.
  StreamSubscription<String>? _refreshSub;

  /// 마지막으로 성공적으로 서버에 등록한 FCM 토큰.
  /// unregister 시점에 다시 getToken() 을 불러도 되지만, Firebase 토큰이
  /// 만료/재발급 된 뒤라면 이전 토큰이 필요하기 때문에 캐시해 둔다.
  String? _lastRegisteredToken;

  /// iOS 에서 APNs 토큰 도착을 기다리는 최대 시간. 첫 설치 직후엔 수 초가
  /// 걸리는 케이스가 있어 넉넉히 잡되, 로그인 흐름이 너무 늦어지지 않도록 10s 로 제한.
  static const Duration _apnsTokenTimeout = Duration(seconds: 10);
  static const Duration _apnsTokenPollInterval = Duration(milliseconds: 500);

  /// `getToken()` 자체 retry 파라미터.
  static const int _getTokenMaxAttempts = 3;
  static const Duration _getTokenRetryDelay = Duration(seconds: 1);

  /// 현재 기기의 FCM 토큰을 가져와 서버에 등록한다.
  ///
  /// 반환값으로 성공/실패를 알고 싶지 않다면 fire-and-forget 으로 호출.
  Future<void> register() async {
    if (kIsWeb) {
      // Web 은 VAPID key 설정이 필요 + 본 프로젝트 타겟 아님.
      return;
    }
    final platform = _detectPlatform();
    if (platform == null) {
      appLogger.w('[FCM] 지원하지 않는 플랫폼 — 토큰 등록 건너뜀');
      return;
    }

    // (1) 첫 시도 실패 케이스를 위해 listener 먼저 부착.
    //     getToken() 이 null 을 돌려준 뒤에도, Firebase 가 나중에 토큰을 발급하면
    //     onTokenRefresh 가 호출되어 자동으로 register 가 완료된다.
    _attachRefreshListenerIfNeeded(platform);

    // (2) iOS 라면 APNs 토큰 도착부터 기다린다.
    if (Platform.isIOS) {
      final apns = await _waitForApnsToken();
      if (apns == null) {
        appLogger.w(
          '[FCM] APNs 토큰을 ${_apnsTokenTimeout.inSeconds}s 안에 못 받음 — '
          '일단 등록 시도는 건너뛰고 onTokenRefresh 에 의존',
        );
        return;
      }
      appLogger.d('[FCM] APNs 토큰 OK (len=${apns.length})');
    }

    // (3) FCM 토큰 조회 (짧은 retry 포함).
    final token = await _getTokenWithRetry();
    if (token == null || token.isEmpty) {
      appLogger.w(
        '[FCM] 디바이스 토큰이 비어있어 등록 건너뜀 — onTokenRefresh 에 의존',
      );
      return;
    }

    // (4) 서버 등록.
    try {
      await _repo.registerDeviceToken(fcmToken: token, platform: platform);
      _lastRegisteredToken = token;
      appLogger.i(
        '[FCM] 디바이스 토큰 등록 완료 (token prefix=${_prefix(token)})',
      );
    } catch (e) {
      // 401/403 (로그인 세션 무효) 혹은 네트워크 오류 모두 여기로 떨어짐.
      // 사용자의 주요 흐름을 막지 않도록 로그만 남긴다.
      appLogger.w('[FCM] 디바이스 토큰 등록 실패: $e');
    }
  }

  /// 현재/마지막 등록된 FCM 토큰을 서버에서 해제한다.
  /// 로그아웃 플로우의 **마지막 단계 직전** 에 호출 — 서버 호출은 아직 인증이 유효해야 한다.
  Future<void> unregister() async {
    if (kIsWeb) return;

    try {
      // 최근 등록한 토큰이 있으면 그걸 우선 사용 (Firebase 가 토큰을 교체한 직후라도
      // 서버엔 과거 토큰으로 레코드가 남아있기 때문).
      final token = _lastRegisteredToken ??
          await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) {
        appLogger.w('[FCM] 해제할 토큰이 없어 건너뜀');
        return;
      }

      await _repo.unregisterDeviceToken(token);
      appLogger.i('[FCM] 디바이스 토큰 해제 완료');
    } catch (e) {
      appLogger.w('[FCM] 디바이스 토큰 해제 실패: $e');
    } finally {
      _lastRegisteredToken = null;
      await _refreshSub?.cancel();
      _refreshSub = null;
    }
  }

  void _attachRefreshListenerIfNeeded(DeviceTokenPlatform platform) {
    _refreshSub ??= FirebaseMessaging.instance.onTokenRefresh.listen(
      (newToken) async {
        // 토큰이 회전되면 서버 쪽 deviceTokenId 는 upsert 로 갱신되므로
        // 구 토큰을 굳이 unregister 할 필요는 없다. 새 토큰만 등록.
        try {
          await _repo.registerDeviceToken(
            fcmToken: newToken,
            platform: platform,
          );
          _lastRegisteredToken = newToken;
          appLogger.i(
            '[FCM] 토큰 refresh → 재등록 완료 (prefix=${_prefix(newToken)})',
          );
        } catch (e) {
          appLogger.w('[FCM] 토큰 refresh 재등록 실패: $e');
        }
      },
    );
  }

  /// iOS 에서 APNs 토큰 도착을 polling 으로 대기.
  /// 도착하면 즉시 토큰을, timeout 이면 null 을 반환.
  Future<String?> _waitForApnsToken() async {
    final deadline = DateTime.now().add(_apnsTokenTimeout);
    while (DateTime.now().isBefore(deadline)) {
      try {
        final apns = await FirebaseMessaging.instance.getAPNSToken();
        if (apns != null && apns.isNotEmpty) {
          return apns;
        }
      } catch (e) {
        // getAPNSToken 자체가 throw 하는 케이스도 가끔 있음 (아직 등록 전).
        // 무시하고 다음 폴링 시도.
      }
      await Future.delayed(_apnsTokenPollInterval);
    }
    return null;
  }

  Future<String?> _getTokenWithRetry() async {
    for (var attempt = 1; attempt <= _getTokenMaxAttempts; attempt++) {
      try {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null && token.isNotEmpty) return token;
      } catch (e) {
        appLogger.w('[FCM] getToken 시도 $attempt 실패: $e');
      }
      if (attempt < _getTokenMaxAttempts) {
        await Future.delayed(_getTokenRetryDelay);
      }
    }
    return null;
  }

  DeviceTokenPlatform? _detectPlatform() {
    if (Platform.isAndroid) return DeviceTokenPlatform.android;
    if (Platform.isIOS) return DeviceTokenPlatform.ios;
    return null;
  }

  /// 토큰 전체를 로그에 남기면 보안상 좋지 않으므로 prefix 만.
  String _prefix(String token) =>
      token.length <= 12 ? token : '${token.substring(0, 12)}…';
}
