import 'package:flutter/foundation.dart';

/// 다마고치 메인 화면 전용 상태.
///
/// 캐릭터 본체(이름/단계/성장률) 는 `characterViewModelProvider`,
/// 오늘의 할 일 / 언젠가 할 일 은 `todoViewModelProvider`,
/// 스트릭(연속 달성) 은 `streakViewModelProvider` 에서 가져온다.
/// 이 상태에는 아직 BE 엔드포인트가 없는 것만 남겨둔다:
///   - [speechBubble] 캐릭터 말풍선 (서버 스펙 확정 전까지 로컬 기본값)
///
/// 성장률/레벨 UI 는 `expToNextLevel = 100` 기준으로 `character.growthPercent`
/// 하나만 쓴다.
@immutable
class TamagochiState {
  const TamagochiState({this.speechBubble});

  /// 캐릭터 말풍선 문구. null 이면 말풍선 숨김.
  final String? speechBubble;

  TamagochiState copyWith({String? speechBubble}) {
    return TamagochiState(
      speechBubble: speechBubble ?? this.speechBubble,
    );
  }

  static const TamagochiState initial = TamagochiState();

  /// 스트릭 시작일 + 현재까지 연속 일수로부터 7칸짜리 주간 인디케이터를 계산한다.
  ///
  /// - `streakDays == 0`: 오늘부터 7일간을 빈 칸으로 표시 (시작 대기 상태).
  /// - `1 ≤ streakDays ≤ 7`: slot[0] = 시작일, 달성한 일수만큼 왼쪽부터 채워짐.
  /// - `streakDays > 7`: 다음 7일 블록으로 통째로 이동. slot[0] 은 (시작일 + 7*n),
  ///   현재 블록에서 달성한 일수만큼 왼쪽부터 채워짐.
  static ({List<bool> slots, List<DateTime> dates}) buildStreakWindow({
    required int streakDays,
    required DateTime? streakStartDate,
    required DateTime today,
  }) {
    final todayOnly = DateTime(today.year, today.month, today.day);

    if (streakDays <= 0 || streakStartDate == null) {
      return (
        slots: List<bool>.filled(7, false),
        dates: List<DateTime>.generate(
          7,
          (i) => todayOnly.add(Duration(days: i)),
        ),
      );
    }

    // 현재 속한 7일 블록의 인덱스. (1~7일 → 0, 8~14일 → 1, ...)
    final blockIndex = (streakDays - 1) ~/ 7;
    final filledInBlock = streakDays - blockIndex * 7; // 1 ~ 7
    final startOnly = DateTime(
      streakStartDate.year,
      streakStartDate.month,
      streakStartDate.day,
    );
    final blockStart = startOnly.add(Duration(days: blockIndex * 7));
    final dates = List<DateTime>.generate(
      7,
      (i) => blockStart.add(Duration(days: i)),
    );
    final slots = List<bool>.generate(7, (i) => i < filledInBlock);
    return (slots: slots, dates: dates);
  }
}
