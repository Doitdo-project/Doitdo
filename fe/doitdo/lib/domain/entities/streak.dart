import 'package:flutter/foundation.dart';

/// 사용자의 연속 달성(스트릭) 도메인 모델.
///
/// `/api/users/me/streak` 응답을 ViewModel 이 다루는 단위로 정규화한 값.
/// - [currentCount] 가 0 이면 [currentStartDate] / [lastActiveDate] 가 null 일 수 있다.
/// - 날짜 필드는 시간 정보를 의미 있게 갖지 않으므로 항상 yyyy-MM-dd 의미로만 사용.
@immutable
class Streak {
  const Streak({
    required this.currentCount,
    required this.longestCount,
    required this.canClaim,
    this.currentStartDate,
    this.lastActiveDate,
    this.longestStartDate,
    this.longestEndDate,
  });

  /// 지금까지 끊기지 않고 이어진 연속 일수. 0 이면 미시작/끊김 상태.
  final int currentCount;

  /// 최장 연속 기록.
  final int longestCount;

  /// 현재 스트릭이 시작된 날짜. [currentCount] 가 0 이면 null.
  final DateTime? currentStartDate;

  /// 마지막으로 스트릭이 적립된 날짜 (가장 최근 활동일).
  final DateTime? lastActiveDate;

  /// 최장 기록의 시작일.
  final DateTime? longestStartDate;

  /// 최장 기록의 종료일.
  final DateTime? longestEndDate;

  /// 지금 보상 수령 가능 여부. BE 가 직접 판정해서 내려준다 —
  /// `currentCount > 0 && currentCount % 7 == 0 && (해당 구간으로 streak_reward_logs
  /// 에 수령 기록 없음)`. 수령 직후엔 false 가 되어 버튼이 자연스럽게 꺼진다.
  /// 클라가 일수만으로 추론하던 시기엔 "이미 받았는데 버튼이 계속 활성" 인 버그가
  /// 있었음 — 그래서 BE 진실에 위임.
  final bool canClaim;

  /// 0 일 때를 위한 빈 값 (네트워크 오류 시 fallback 으로도 사용 가능).
  static const Streak empty =
      Streak(currentCount: 0, longestCount: 0, canClaim: false);

  /// 현재 7일 블록에서 채워진 칸 수 (1~7). [currentCount] 가 0 이면 0.
  int get filledInCurrentBlock {
    if (currentCount <= 0) return 0;
    final blockIndex = (currentCount - 1) ~/ 7;
    return currentCount - blockIndex * 7;
  }

  /// 7일 블록의 마지막 날(=수령 가능 시점) 에 도달했는지. 수령 여부와 무관 —
  /// "오늘 슬롯이 7개 다 채워졌느냐" 만 본다. 수령 가능 여부는 [canClaim] 사용.
  bool get isAtBlockEnd => currentCount > 0 && filledInCurrentBlock == 7;
}

/// `POST /api/users/me/streak/rewards` 결과.
///
/// [rewarded] false 이면 이미 수령했거나 수령 불가 상태 → UI 는 안내만 띄운다.
@immutable
class StreakReward {
  const StreakReward({
    required this.rewarded,
    required this.streakCount,
    required this.rewardAmount,
    required this.balance,
  });

  /// 이번 호출로 실제 보상이 지급됐는지. false 면 [rewardAmount] 는 0.
  final bool rewarded;

  /// 보상 지급 시점의 스트릭 일수 (서버 기준).
  final int streakCount;

  /// 이번에 지급된 코인량.
  final int rewardAmount;

  /// 지급 후 사용자의 코인 잔액.
  final int balance;
}
