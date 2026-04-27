import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:doitdo/presentation/providers/app_data_providers.dart';

/// 사용자 프로필 이미지 경로(로컬 파일 경로) 상태.
///
/// null 이면 기본(아이콘) 아바타를 표시. 앱 재시작에도 유지되도록 SharedPreferences 영속.
/// 추후 서버 업로드 지원 시 URL 타입도 함께 허용하도록 확장 (URI 파싱으로 분기 처리).
class ProfileImageNotifier extends StateNotifier<String?> {
  ProfileImageNotifier(this._prefs) : super(_prefs.getString(_key));

  static const String _key = 'profile_image_path';
  final SharedPreferences _prefs;

  Future<void> set(String? path) async {
    state = path;
    if (path == null) {
      await _prefs.remove(_key);
    } else {
      await _prefs.setString(_key, path);
    }
  }
}

final profileImageProvider =
    StateNotifierProvider<ProfileImageNotifier, String?>((ref) {
  return ProfileImageNotifier(ref.watch(sharedPreferencesProvider));
});
