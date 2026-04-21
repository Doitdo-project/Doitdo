import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/presentation/pages/tamagochi/tamagochi_state.dart';

/// 다마고치 메인 화면의 ViewModel.
///
/// 현재는 API 가 없어 `TamagochiState.mock` 을 그대로 사용하고,
/// 할 일 체크 토글 같은 로컬 상호작용만 담당한다.
///
/// Repository 가 붙으면 `ref` 로 주입받아 `load()` 에서 실제 데이터를
/// 가져오도록 확장한다.
class TamagochiViewModel extends StateNotifier<TamagochiState> {
  TamagochiViewModel() : super(TamagochiState.mock);

  /// 오늘의 할 일 완료 토글.
  void toggleTodayTodo(String id) {
    state = state.copyWith(
      todayTodos: [
        for (final t in state.todayTodos)
          if (t.id == id) t.copyWith(isDone: !t.isDone) else t,
      ],
    );
  }

  /// "언젠가 할 일" 완료 토글.
  void toggleSomedayTodo(String id) {
    state = state.copyWith(
      somedayTodos: [
        for (final t in state.somedayTodos)
          if (t.id == id) t.copyWith(isDone: !t.isDone) else t,
      ],
    );
  }
}

final tamagochiViewModelProvider =
    StateNotifierProvider.autoDispose<TamagochiViewModel, TamagochiState>(
  (ref) => TamagochiViewModel(),
);