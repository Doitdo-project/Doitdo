import 'package:doitdo/presentation/models/todo.dart';
import 'package:flutter/foundation.dart';

/// 다마고치 메인 화면에서 보여줄 상태 묶음.
///
/// `Todo`, `TodoCategory`, `CategoryColorKey` 는 공유 모델(`presentation/models/todo.dart`)
/// 에서 가져온다. 이 파일에는 다마고치 화면에만 해당하는 상태만 둔다.

@immutable
class TamagochiState {
  const TamagochiState({
    required this.characterName,
    required this.level,
    required this.currentExp,
    required this.expToNextLevel,
    required this.speechBubble,
    required this.streakDays,
    required this.streakStartDate,
    required this.streakSlots,
    required this.streakSlotDates,
    required this.todayTodos,
    required this.somedayTodos,
  });

  final String characterName;
  final int level;
  final int currentExp;
  final int expToNextLevel;

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

  final List<Todo> todayTodos;
  final List<Todo> somedayTodos;

  double get expProgress =>
      expToNextLevel == 0 ? 0 : currentExp / expToNextLevel;

  TamagochiState copyWith({
    String? speechBubble,
    List<Todo>? todayTodos,
    List<Todo>? somedayTodos,
  }) {
    return TamagochiState(
      characterName: characterName,
      level: level,
      currentExp: currentExp,
      expToNextLevel: expToNextLevel,
      speechBubble: speechBubble ?? this.speechBubble,
      streakDays: streakDays,
      streakStartDate: streakStartDate,
      streakSlots: streakSlots,
      streakSlotDates: streakSlotDates,
      todayTodos: todayTodos ?? this.todayTodos,
      somedayTodos: somedayTodos ?? this.somedayTodos,
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

  /// 디자인 시안 기준 더미 초기값.
  /// API 붙기 전까지 ViewModel 이 이 값을 그대로 반환한다.
  static TamagochiState get mock {
    final today = DateTime.now();
    const mockStreakDays = 3;
    final streakStart = DateTime(today.year, today.month, today.day)
        .subtract(const Duration(days: mockStreakDays - 1));
    final window = buildStreakWindow(
      streakDays: mockStreakDays,
      streakStartDate: streakStart,
      today: today,
    );
    return TamagochiState(
      characterName: '오둥이',
      level: 3,
      currentExp: 450,
      expToNextLevel: 600,
      speechBubble: '아직 할 일이 남았어...',
      streakDays: mockStreakDays,
      streakStartDate: streakStart,
      streakSlots: window.slots,
      streakSlotDates: window.dates,
      todayTodos: [
      const Todo(
        id: 't1',
        title: '아침 명상 10분 하기',
        category: _health,
        isDone: true,
      ),
      const Todo(
        id: 't2',
        title: '아침 명상 10분 하기',
        category: _health,
        isDone: false,
      ),
      const Todo(
        id: 't3',
        title: '아침 명상 10분 하기',
        category: _health,
        isDone: false,
      ),
      const Todo(
        id: 't3',
        title: '아침 명상 10분 하기',
        category: _health,
        isDone: false,
      ),
      const Todo(
        id: 't3',
        title: '아침 명상 10분 하기',
        category: _health,
        isDone: false,
      ),
      const Todo(
        id: 't3',
        title: '아침 명상 10분 하기',
        category: _health,
        isDone: false,
      ),
      const Todo(
        id: 't3',
        title: '아침 명상 10분 하기',
        category: _health,
        isDone: false,
      ),
    ],
    somedayTodos: [
      const Todo(
        id: 's1',
        title: '아침 명상 10분 하기',
        category: _health,
        isDone: false,
      ),
    ],
  );
  }

  static const TodoCategory _health = TodoCategory(
    name: '건강',
    colorKey: CategoryColorKey.health,
  );
}
