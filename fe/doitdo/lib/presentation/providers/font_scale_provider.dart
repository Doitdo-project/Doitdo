import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:doitdo/presentation/providers/app_data_providers.dart';

class FontScaleNotifier extends StateNotifier<double> {
  FontScaleNotifier(this._prefs) : super(_read(_prefs));

  static const String _key = 'font_scale';
  static const double min = 0.8;
  static const double max = 1.2;
  static const double defaultScale = 1.0;

  final SharedPreferences _prefs;

  static double _read(SharedPreferences prefs) {
    final saved = prefs.getDouble(_key) ?? defaultScale;
    return saved.clamp(min, max);
  }

  Future<void> set(double scale) async {
    state = scale.clamp(min, max);
    await _prefs.setDouble(_key, state);
  }
}

final fontScaleProvider =
    StateNotifierProvider<FontScaleNotifier, double>((ref) {
  return FontScaleNotifier(ref.watch(sharedPreferencesProvider));
});
