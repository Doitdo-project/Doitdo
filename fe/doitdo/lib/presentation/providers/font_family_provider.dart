import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:doitdo/presentation/providers/app_data_providers.dart';

/// 사용자가 선택할 수 있는 앱 전역 폰트.
///
/// 각 enum 의 [family] 는 pubspec.yaml 의 fonts 섹션에 등록된 family 이름과
/// 정확히 일치해야 한다. [label] 은 설정 시트/타일에 노출되는 한글 라벨.
enum AppFontFamily {
  gmarketSans(family: 'GmarketSans', label: 'G마켓 산스'),
  pretendard(family: 'Pretendard', label: '프리텐다드');

  const AppFontFamily({required this.family, required this.label});

  final String family;
  final String label;
}

/// 앱 전역 폰트 family 를 SharedPreferences 에 영속 저장하는 Notifier.
///
/// `ThemeData.fontFamily` 에 이 값이 주입되어 모든 Text 위젯의 기본 폰트가
/// 결정된다. AppTextStyles 의 각 TextStyle 은 fontFamily 를 명시하지 않으므로
/// 이 설정 한 곳만 바꾸면 앱 전체 폰트가 즉시 전환된다.
class FontFamilyNotifier extends StateNotifier<AppFontFamily> {
  FontFamilyNotifier(this._prefs) : super(_read(_prefs));

  static const String _key = 'font_family';
  static const AppFontFamily defaultFamily = AppFontFamily.gmarketSans;

  final SharedPreferences _prefs;

  static AppFontFamily _read(SharedPreferences prefs) {
    final saved = prefs.getString(_key);
    if (saved == null) return defaultFamily;
    return AppFontFamily.values.firstWhere(
      (f) => f.name == saved,
      orElse: () => defaultFamily,
    );
  }

  Future<void> set(AppFontFamily family) async {
    state = family;
    await _prefs.setString(_key, family.name);
  }
}

final fontFamilyProvider =
    StateNotifierProvider<FontFamilyNotifier, AppFontFamily>((ref) {
  return FontFamilyNotifier(ref.watch(sharedPreferencesProvider));
});
