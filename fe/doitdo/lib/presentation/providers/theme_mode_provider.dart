import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:doitdo/presentation/providers/app_data_providers.dart';

/// 테마 모드(라이트/다크) 상태.
///
/// - `MaterialApp.themeMode` 에 연결되어 전체 앱 외관을 결정한다.
/// - `SharedPreferences` 에 저장돼 앱 재시작 후에도 유지된다.
/// - **기본값은 라이트.** 시스템 설정이 다크라도 doitdo 첫 진입은 라이트로 통일한다
///   (브랜드 일러스트/크림 톤이 라이트에 최적화돼 있어서). 사용자가 설정에서
///   다크를 선택하면 그때부터 적용된다.
/// - 추후 사용자 커스텀 테마가 추가되면 이 Notifier에 컬러 팔레트 상태도
///   함께 관리하도록 확장할 수 있다.
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._prefs) : super(_read(_prefs));

  static const String _key = 'theme_mode';
  final SharedPreferences _prefs;

  static ThemeMode _read(SharedPreferences prefs) {
    switch (prefs.getString(_key)) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        // 저장된 적 없거나 'system' 같은 레거시 값 — 라이트로 폴백.
        return ThemeMode.light;
    }
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await _prefs.setString(_key, mode.name);
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(ref.watch(sharedPreferencesProvider));
});