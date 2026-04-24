import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/presentation/pages/tamagochi/tamagochi_state.dart';

/// 다마고치 메인 화면의 ViewModel.
///
/// 캐릭터(이름/성장률) 는 `characterViewModelProvider`, 할 일 목록은
/// `todoViewModelProvider` 에서 직접 watch 한다. 이 ViewModel 에는 BE 엔드포인트가
/// 아직 없는 말풍선 / 스트릭 상태만 남아있다.
class TamagochiViewModel extends StateNotifier<TamagochiState> {
  TamagochiViewModel() : super(TamagochiState.initial);
}

final tamagochiViewModelProvider =
    StateNotifierProvider.autoDispose<TamagochiViewModel, TamagochiState>(
  (ref) => TamagochiViewModel(),
);