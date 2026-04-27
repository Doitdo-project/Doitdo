import 'package:doitdo/core/network/base_repository.dart';
import 'package:doitdo/data/datasources/setting_api.dart';
import 'package:doitdo/data/models/setting_dto.dart';
import 'package:doitdo/domain/repositories/setting_repository.dart';

class SettingRepositoryImpl extends BaseRepository implements SettingRepository {
  SettingRepositoryImpl(this._api);

  final SettingApi _api;

  @override
  Future<UserSettingResp> getSetting() =>
      safeApiCall(() => _api.getSetting());

  @override
  Future<UserSettingResp> updateSetting(Map<String, dynamic> body) =>
      safeApiCall(() => _api.updateSetting(body));
}
