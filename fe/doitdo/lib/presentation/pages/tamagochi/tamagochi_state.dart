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

  /// 주간 스트릭 인디케이터 (7칸, true=달성 / false=미달성).
  /// 길이는 반드시 7. 왼→오 방향으로 과거 → 오늘 순서.
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
      streakSlots: streakSlots,
      streakSlotDates: streakSlotDates,
      todayTodos: todayTodos ?? this.todayTodos,
      somedayTodos: somedayTodos ?? this.somedayTodos,
    );
  }

  /// 디자인 시안 기준 더미 초기값.
  /// API 붙기 전까지 ViewModel 이 이 값을 그대로 반환한다.
  static TamagochiState get mock {
    final today = DateTime.now();
    // 왼→오 방향: 6일 전 → 오늘. 인덱스 i 는 (6 - i) 일 전.
    final dates = List<DateTime>.generate(
      7,
      (i) => DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: 6 - i)),
    );
    return TamagochiState(
      characterName: '오둥이',
      level: 3,
      currentExp: 450,
      expToNextLevel: 600,
      speechBubble: '아직 할 일이 남았어...',
      streakDays: 3,
      // 최근 3일(오늘 포함) 연속 달성 중인 상태.
      streakSlots: const [false, false, false, false, true, true, true],
      streakSlotDates: dates,
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
