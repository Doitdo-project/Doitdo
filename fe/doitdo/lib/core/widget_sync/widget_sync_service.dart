import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:home_widget/home_widget.dart';
import 'package:logger/logger.dart';

import 'package:doitdo/core/widget_sync/widget_todo_dto.dart';

/// 홈스크린 위젯과의 데이터 동기화 단일 진입점.
///
/// 책임:
/// - 앱이 가진 TODO 목록 / 인증 토큰을 OS 공유 저장소(iOS App Group / Android SharedPreferences) 에 직렬화 저장
/// - 위젯 갱신 트리거 호출 (`HomeWidget.updateWidget`)
/// - 로그아웃 / 회원탈퇴 시 위젯 데이터 클리어
///
/// 호출 위치:
/// - [TodoRepositoryImpl] 의 변경 메서드(create/update/changeStatus/delete) 종료 시점
/// - [AuthRepositoryImpl] 의 로그인/refresh/signOut 시점
/// - 앱 foreground 진입 시 (`AppLifecycleState.resumed`) — main.dart 에서 옵저버 등록
///
/// 웹/macOS/Linux 빌드에서는 모든 메서드가 no-op (홈 위젯이 없는 플랫폼).
class WidgetSyncService {
  WidgetSyncService({Logger? logger}) : _log = logger ?? Logger();

  static const String _iOSAppGroupId = 'group.com.d107.doitdo';
  static const String _iOSWidgetName = 'DoitdoWidget';
  static const String _androidWidgetProvider = 'DoitdoWidgetProvider';

  // App Group / SharedPreferences 키.
  // 네이티브(Swift / Kotlin) 코드에서도 동일 키로 read 한다 — 변경 시 양쪽 동기화 필수.
  static const String _keyPayload = 'doitdo.widget.payload';
  static const String _keyAccessToken = 'doitdo.widget.accessToken';
  static const String _keyRefreshToken = 'doitdo.widget.refreshToken';
  static const String _keyApiBaseUrl = 'doitdo.widget.apiBaseUrl';

  final Logger _log;

  bool _initialized = false;

  /// 앱 시작 시 1회 호출 (`main.dart` 의 `runApp` 직전).
  ///
  /// iOS 의 App Group 식별자를 home_widget 에 알려준다. Android 는 별도 설정 불필요.
  Future<void> init() async {
    if (_initialized) return;
    if (!_isSupported()) return;
    try {
      await HomeWidget.setAppGroupId(_iOSAppGroupId);
      _initialized = true;
    } catch (e, st) {
      _log.w('WidgetSyncService init 실패 (위젯 비활성화 상태로 계속): $e', stackTrace: st);
    }
  }

  /// TODO 목록을 위젯에 전송. 변경이 있을 때마다 호출 — 너무 잦은 호출은 OS 가 throttling 한다.
  ///
  /// [todayTodos] 는 오늘 표시할 일반/반복/기간 TODO,
  /// [somedayTodos] 는 type=SOMEDAY TODO. 위젯에서 두 섹션을 분리 렌더한다.
  /// 위젯 표시 한도는 네이티브 측에서 자른다 (Medium 기준 5~7개).
  Future<void> syncTodos({
    required List<WidgetTodoDto> todayTodos,
    required List<WidgetTodoDto> somedayTodos,
  }) async {
    if (!_isSupported()) return;
    final payload = WidgetPayload(
      todayTodos: todayTodos,
      somedayTodos: somedayTodos,
      updatedAt: DateTime.now(),
    );
    await _save(_keyPayload, jsonEncode(payload.toJson()));
    await _refreshWidget();
  }

  /// 로그인/토큰 갱신 시 호출. 위젯의 백그라운드 AppIntent(iOS 17+) 가 PATCH 호출에 사용한다.
  ///
  /// 보안 주의: App Group UserDefaults 는 같은 App Group 에 속한 extension 만 접근 가능하지만
  /// 디바이스가 탈옥 상태라면 노출 가능. 추후 Keychain Access Group 으로 이전 검토.
  Future<void> syncAuthTokens({
    required String accessToken,
    required String refreshToken,
    required String apiBaseUrl,
  }) async {
    if (!_isSupported()) return;
    await _save(_keyAccessToken, accessToken);
    await _save(_keyRefreshToken, refreshToken);
    await _save(_keyApiBaseUrl, apiBaseUrl);
    // 토큰 변경 자체로는 위젯 UI 가 안 바뀌니 reload 불필요.
  }

  /// 로그아웃 / 회원탈퇴 시 호출 — 위젯에 남아있는 모든 데이터를 비운다.
  ///
  /// 위젯은 비어있는 상태에서 "로그인이 필요해요" 안내를 표시한다 (네이티브 측 처리).
  Future<void> clearAll() async {
    if (!_isSupported()) return;
    await _save(_keyPayload, '');
    await _save(_keyAccessToken, '');
    await _save(_keyRefreshToken, '');
    // apiBaseUrl 은 다음 로그인에서 다시 set 되므로 비우지 않아도 무방.
    await _refreshWidget();
  }

  Future<void> _save(String key, String value) async {
    try {
      await HomeWidget.saveWidgetData<String>(key, value);
    } catch (e, st) {
      _log.w('WidgetSyncService 저장 실패 (key=$key): $e', stackTrace: st);
    }
  }

  Future<void> _refreshWidget() async {
    try {
      await HomeWidget.updateWidget(
        name: _androidWidgetProvider,
        iOSName: _iOSWidgetName,
      );
    } catch (e, st) {
      _log.w('WidgetSyncService 위젯 갱신 실패: $e', stackTrace: st);
    }
  }

  /// 홈 위젯이 의미가 있는 플랫폼 판정. 웹/데스크톱은 no-op.
  bool _isSupported() {
    if (kIsWeb) return false;
    return Platform.isIOS || Platform.isAndroid;
  }
}
