import 'package:doitdo/data/models/setting_dto.dart';

abstract class SettingRepository {
  Future<UserSettingResp> getSetting();

  /// null 필드는 서버에서 기존값을 유지한다 (PATCH 부분 업데이트).
  Future<UserSettingResp> updateSetting(Map<String, dynamic> body);
}
