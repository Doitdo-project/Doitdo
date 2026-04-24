import 'package:flutter/foundation.dart';

/// 다마고치 메인 화면 전용 상태.
///
/// 캐릭터 본체(이름/단계/성장률) 는 `characterViewModelProvider`,
/// 오늘의 할 일 / 언젠가 할 일 은 `todoViewModelProvider` 에서 가져온다.
/// 이 상태에는 아직 BE 엔드포인트가 없는 것만 남겨둔다:
///   - [speechBubble] 캐릭터 말풍선 (서버 스펙 확정 전까지 로컬 기본값)
///   - 스트릭 관련 필드 (User.streakCount 만 존재, 시작일/7일 윈도우 API 미정)
///
/// 성장률/레벨 UI 는 `expToNextLevel = 100` 기준으로 `character.growthPercent`
/// 하나만 쓴다.
@immutable
class TamagochiState {
  const TamagochiState({
    required this.speechBubble,
    required this.streakDays,
    required this.streakStartDate,
    required this.streakSlots,
    required this.streakSlotDates,
  });

  /// 캐릭터 말풍선 문구. null 이면 말풍선 숨김.
  final String? speechBubble;

  /// 현재까지 연속 달성한 일 수.
  final int streakDays;

  /// 현재 스트릭이 시작된 날짜. 스트릭이 끊기고 다시 시작되면 그 날짜로 갱신된다.
  /// [streakDays] 가 0 이면 null.
  final DateTime? streakStartDate;

  /// 주간 스트릭 인디케이터 (7칸, true=달성 / false=미달성).
  /// 길이는 반드시 7. slot[0] 은 현재 7일 블록의 시작일이고,
  /// 스트릭이 7일을 넘기면 다음 7일 블록으로 통째로 이동한다.
  final List<bool> streakSlots;

  /// 각 스트릭 칸에 대응하는 날짜. [streakSlots] 와 1:1 매칭. 길이 반드시 7.
  final List<DateTime> streakSlotDates;

  TamagochiState copyWith({
    String? speechBubble,
    int? streakDays,
    DateTime? streakStartDate,
    List<bool>? streakSlots,
    List<DateTime>? streakSlotDates,
  }) {
    return TamagochiState(
      speechBubble: speechBubble ?? this.speechBubble,
      streakDays: streakDays ?? this.streakDays,
      streakStartDate: streakStartDate ?? this.streakStartDate,
      streakSlots: streakSlots ?? this.streakSlots,
      streakSlotDates: streakSlotDates ?? this.streakSlotDates,
    );
  }

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

  /// 스트릭 / 말풍선 BE 스펙이 확정되기 전까지 기본값.
  /// TODO(BE): 전용 엔드포인트 나오면 ViewModel 에서 서버 값으로 교체.
  static TamagochiState get initial {
    final today = DateTime.now();
    final window = buildStreakWindow(
      streakDays: 0,
      streakStartDate: null,
      today: today,
    );
    return TamagochiState(
      speechBubble: null,
      streakDays: 0,
      streakStartDate: null,
      streakSlots: window.slots,
      streakSlotDates: window.dates,
    );
  }
}