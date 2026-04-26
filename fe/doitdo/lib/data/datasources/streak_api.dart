import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'package:doitdo/core/network/api_response.dart';
import 'package:doitdo/data/models/streak_dto.dart';
import 'package:doitdo/data/models/streak_reward_dto.dart';

part 'streak_api.g.dart';

/// `/api/users/me/streak*` 엔드포인트 그룹.
///
/// envelope(`{status, message, data}`) 은 [ApiResponse] 로 감싸고
/// RepositoryImpl 의 `safeApiCall` 이 벗겨낸다.
///
/// 새 엔드포인트 추가 후에는 반드시:
///   dart run build_runner build --delete-conflicting-outputs
@RestApi()
abstract class StreakApi {
  factory StreakApi(Dio dio, {String baseUrl}) = _StreakApi;

  /// 현재 사용자의 스트릭 상태 조회.
  @GET('/api/users/me/streak')
  Future<ApiResponse<StreakDto>> getStreak();

  /// 7일 블록 완성 등 보상 조건 충족 시 호출. 이미 받았으면 BE 가
  /// `data.rewarded = false` 로 응답하므로 예외 처리는 필요 없다.
  @POST('/api/users/me/streak/rewards')
  Future<ApiResponse<StreakRewardDto>> claimReward();
}
