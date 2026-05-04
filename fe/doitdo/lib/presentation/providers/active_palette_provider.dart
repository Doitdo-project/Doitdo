import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:doitdo/presentation/providers/app_data_providers.dart';

/// 카테고리 색상에 사용할 활성 팔레트 ID.
///
/// 사용자는 카테고리 설정 페이지 상단의 좌우 화살표로 팔레트를 바꾼다.
/// 화살표를 누르면 이 값이 갱신되고, 모든 카테고리가 새 팔레트의 같은 인덱스
/// 색으로 일괄 PATCH 된다 ([CategoryViewModel.applyPaletteToAll]).
///
/// 카테고리 추가/수정 시트는 이 값을 그대로 따라가, 활성 팔레트의 색만
/// 그리드로 노출한다(시트 안에서 다른 팔레트로 못 넘어감).
///
/// 저장: SharedPreferences. 처음 진입한 사용자는 null — 카테고리 페이지가
/// paletteProvider 데이터를 받자마자 첫 팔레트 ID 를 자동 설정한다.
class ActivePaletteNotifier extends StateNotifier<int?> {
  ActivePaletteNotifier(this._prefs) : super(_read(_prefs));

  static const String _key = 'active_palette_id';
  final SharedPreferences _prefs;

  static int? _read(SharedPreferences prefs) => prefs.getInt(_key);

  Future<void> set(int paletteId) async {
    state = paletteId;
    await _prefs.setInt(_key, paletteId);
  }

  Future<void> clear() async {
    state = null;
    await _prefs.remove(_key);
  }
}

final activePaletteProvider =
    StateNotifierProvider<ActivePaletteNotifier, int?>((ref) {
  return ActivePaletteNotifier(ref.watch(sharedPreferencesProvider));
});
