import 'package:doitdo/domain/entities/streak.dart';

/// 사용자 스트릭(연속 달성) 도메인 추상화.
///
/// 엔드포인트:
/// - `GET  /api/users/me/streak`         → [getStreak]
/// - `POST /api/users/me/streak/rewards` → [claimReward]
abstract class StreakRepository {
  /// 현재 사용자의 스트릭 상태 조회.
  ///
  /// 한 번도 활동이 없는 사용자에 대해 서버가 어떻게 응답할지 명세가 확정되기 전까지는
  /// 0/null 로 채워진 [Streak] 가 내려온다고 가정한다. 진짜 네트워크/서버 에러는
  /// `ServerException` / `NetworkException` 으로 throw 된다.
  Future<Streak> getStreak();

  /// 7일 블록 완성 등 보상 조건 충족 시 호출. 이미 수령했으면
  /// [StreakReward.rewarded] 가 false 로 내려온다 (예외 아님).
  Future<StreakReward> claimReward();
}
