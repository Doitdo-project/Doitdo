import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:doitdo/presentation/providers/app_data_providers.dart';

/// 앱 진입 시 기본으로 표시될 탭.
///
/// - [home]: 다마고치 홈 (오늘의 할 일 + 캐릭터)
/// - [calendar]: 할 일 캘린더 탭 (날짜별 기록)
///
/// 실제 초기 라우팅 반영은 SplashPage / GoRouter 의 `redirect` 로 처리 예정.
enum DefaultScreen { home, calendar }

class DefaultScreenNotifier extends StateNotifier<DefaultScreen> {
  DefaultScreenNotifier(this._prefs) : super(_read(_prefs));

  static const String _key = 'default_screen';
  final SharedPreferences _prefs;

  static DefaultScreen _read(SharedPreferences prefs) {
    switch (prefs.getString(_key)) {
      case 'calendar':
        return DefaultScreen.calendar;
      case 'home':
      default:
        return DefaultScreen.home;
    }
  }

  Future<void> set(DefaultScreen screen) async {
    state = screen;
    await _prefs.setString(_key, screen.name);
  }
}

final defaultScreenProvider =
    StateNotifierProvider<DefaultScreenNotifier, DefaultScreen>((ref) {
  return DefaultScreenNotifier(ref.watch(sharedPreferencesProvider));
});
