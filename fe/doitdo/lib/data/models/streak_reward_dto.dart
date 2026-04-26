import 'package:doitdo/domain/entities/streak.dart';

/// `POST /api/users/me/streak/rewards` 응답 DTO.
///
/// ```json
/// { "rewarded": true, "streakCount": 0, "rewardAmount": 0, "balance": 0 }
/// ```
class StreakRewardDto {
  const StreakRewardDto({
    required this.rewarded,
    required this.streakCount,
    required this.rewardAmount,
    required this.balance,
  });

  final bool rewarded;
  final int streakCount;
  final int rewardAmount;
  final int balance;

  factory StreakRewardDto.fromJson(Map<String, dynamic> json) {
    return StreakRewardDto(
      rewarded: (json['rewarded'] as bool?) ?? false,
      streakCount: (json['streakCount'] as num?)?.toInt() ?? 0,
      rewardAmount: (json['rewardAmount'] as num?)?.toInt() ?? 0,
      balance: (json['balance'] as num?)?.toInt() ?? 0,
    );
  }

  StreakReward toEntity() => StreakReward(
        rewarded: rewarded,
        streakCount: streakCount,
        rewardAmount: rewardAmount,
        balance: balance,
      );
}
