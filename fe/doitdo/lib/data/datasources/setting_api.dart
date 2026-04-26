import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'package:doitdo/core/network/api_response.dart';
import 'package:doitdo/data/models/setting_dto.dart';

part 'setting_api.g.dart';

@RestApi()
abstract class SettingApi {
  factory SettingApi(Dio dio, {String baseUrl}) = _SettingApi;

  // 방해금지·아침·저녁 리마인드 설정 조회
  @GET('/api/settings')
  Future<ApiResponse<UserSettingResp>> getSetting();

  // 부분 업데이트 — null 필드는 기존값 유지
  @PATCH('/api/settings')
  Future<ApiResponse<UserSettingResp>> updateSetting(
    @Body() Map<String, dynamic> body,
  );
}
