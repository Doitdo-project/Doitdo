import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Offset;

/// 캐릭터 탭으로 코인을 획득한 1회성 시그널.
///
/// 매 탭마다 [tick] 이 증가하므로 같은 amount/origin 이 다시 떨어져도 부모가
/// "새 이벤트" 로 구분해 floating "+N" 위젯을 다시 띄울 수 있다.
@immutable
class CharacterTapGain {
  const CharacterTapGain({
    required this.amount,
    required this.origin,
    required this.tick,
  });

  /// 이번 탭으로 지급된 코인량. 항상 > 0 — 0 이면 호출자가 시그널을 만들지 않는다.
  final int amount;

  /// 사용자가 탭한 위치 (글로벌 좌표). 페이지가 outer Stack 의 Positioned 로
  /// 그대로 사용해 손가락 자리에서 위로 솟아오르는 연출을 만든다.
  final Offset origin;

  /// 단조증가 시퀀스 — 같은 amount 가 또 와도 위젯 key 가 바뀌도록.
  final int tick;
}

/// 다마고치 메인 화면 전용 상태.
///
/// 캐릭터 본체(이름/단계/성장률) 는 `characterViewModelProvider`,
/// 오늘의 할 일 / 언젠가 할 일 은 `todoViewModelProvider`,
/// 스트릭(연속 달성) 은 `streakViewModelProvider` 에서 가져온다.
/// 이 상태에는 아직 BE 엔드포인트가 없거나, 화면 단일 소유 데이터만 남겨둔다:
///   - [speechBubble] 캐릭터 말풍선 (tap 인터랙션으로 갱신)
///   - [actionUrl] 마지막 action 응답으로 받은 동작 gif URL.
///                 null 이면 평상시(로컬 EYE gif) 그대로, 값이 있으면 그 gif 로 swap.
///   - [actionTick] 같은 url 이 다시 떨어졌을 때 Image.network 가 캐시 때문에
///                 재생을 처음부터 안 하는 걸 막기 위한 단조증가 카운터.
///                 위젯 key 에 섞어 강제 remount 시킨다.
///   - [lastGain] 마지막 캐릭터 탭에서 코인이 지급됐을 때의 시그널.
///
/// 성장률/레벨 UI 는 `expToNextLevel = 100` 기준으로 `character.growthPercent`
/// 하나만 쓴다.
@immutable
class TamagochiState {
  const TamagochiState({
    this.speechBubble,
    this.speechBubblePinned = false,
    this.actionUrl,
    this.actionTick = 0,
    this.lastGain,
  });

  /// 캐릭터 말풍선 문구. null 이면 말풍선 숨김.
  final String? speechBubble;

  /// true 이면 [_AutoToggledBubble] 이 자동 fade-out 하지 않고 계속 노출한다.
  final bool speechBubblePinned;

  /// 마지막 action 응답으로 받은 gif URL. null 이면 평상시(로컬 EYE gif) 사용.
  final String? actionUrl;

  /// action 응답 도착마다 증가. 같은 URL 이 또 와도 widget key 가 바뀌면서
  /// gif 가 처음부터 다시 재생되도록 한다.
  final int actionTick;

  /// 마지막 캐릭터 탭에서 받은 코인 획득 시그널. null 이면 아직 없거나 한도 초과로
  /// 미지급. tick 변화로 부모가 새 이벤트를 감지한다.
  final CharacterTapGain? lastGain;

  TamagochiState copyWith({
    String? speechBubble,
    bool? speechBubblePinned,
    String? actionUrl,
    int? actionTick,
    bool clearActionUrl = false,
    CharacterTapGain? lastGain,
  }) {
    return TamagochiState(
      speechBubble: speechBubble ?? this.speechBubble,
      speechBubblePinned: speechBubblePinned ?? this.speechBubblePinned,
      // copyWith 의 nullable 파라미터는 null 을 "변경 없음" 으로 다루기 때문에
      // 명시적으로 null 로 되돌리려면 [clearActionUrl] 플래그를 사용한다.
      actionUrl: clearActionUrl ? null : (actionUrl ?? this.actionUrl),
      actionTick: actionTick ?? this.actionTick,
      // lastGain 도 동일 룰 — null 전달 시 변경 없음. 한도 초과로 미지급된
      // 탭에서는 lastGain 을 건드리지 않으므로 부모는 prev?.lastGain?.tick 비교로
      // 새 이벤트만 감지하면 된다.
      lastGain: lastGain ?? this.lastGain,
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
