import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/core/utils/app_logger.dart';
import 'package:doitdo/domain/entities/streak.dart';
import 'package:doitdo/domain/repositories/streak_repository.dart';
import 'package:doitdo/presentation/providers/app_data_providers.dart';

/// 현재 사용자의 스트릭 상태.
///
/// `AsyncValue<Streak>` 으로 표현 — 서버가 미활동 사용자에 대해서도 0/null 로
/// 채워진 페이로드를 내려준다고 가정하므로 `Streak?` 가 아닌 `Streak` 를 사용.
/// 네트워크 실패 시에는 [Streak.empty] 를 fallback 으로 노출하지 않고 error 로 둔다
/// (UI 가 "🔥 0일 연속" 을 잘못 보여주는 걸 막기 위함).
class StreakViewModel extends StateNotifier<AsyncValue<Streak>> {
  StreakViewModel(this._repository) : super(const AsyncValue.loading()) {
    load();
  }

  final StreakRepository _repository;

  /// 스트릭 조회. 직전 값을 유지한 채 isLoading 만 켜서 깜빡임을 줄인다.
  Future<void> load() async {
    state = const AsyncValue<Streak>.loading().copyWithPrevious(state);
    try {
      final streak = await _repository.getStreak();
      state = AsyncValue.data(streak);
    } catch (e, st) {
      appLogger.e('streak load failed', error: e, stackTrace: st);
      state = AsyncValue.error(e, st);
    }
  }

  /// state 를 loading 으로 전환하지 않는 백그라운드 리프레시.
  /// (할 일 완료 직후처럼 holds-its-current-data 가 더 자연스러운 상황용)
  Future<void> refresh() async {
    try {
      final streak = await _repository.getStreak();
      state = AsyncValue.data(streak);
    } catch (e, st) {
      appLogger.e('streak refresh failed (silent)', error: e, stackTrace: st);
    }
  }

  /// 7일 블록 완성 시 보상 수령. 이미 받았으면 BE 가 `rewarded=false` 로 응답하므로
  /// 호출자가 [StreakReward.rewarded] 분기로 메시지를 다르게 띄우면 된다.
  ///
  /// 동시 탭 방지용 in-flight 플래그. true 가 반환됐다고 보상이 지급된 건 아니고,
  /// 호출이 정상 완료됐는지만 의미한다.
  bool _claiming = false;
  Future<StreakReward?> claimReward() async {
    if (_claiming) return null;
    _claiming = true;
    try {
      final reward = await _repository.claimReward();
      // 보상이 지급됐으면 streakCount 가 갱신됐을 수 있으니 한 번 더 동기화.
      if (reward.rewarded) {
        await refresh();
      }
      return reward;
    } catch (e, st) {
      appLogger.e('streak claim failed', error: e, stackTrace: st);
      return null;
    } finally {
      _claiming = false;
    }
  }
}

final streakViewModelProvider =
    StateNotifierProvider.autoDispose<StreakViewModel, AsyncValue<Streak>>(
  (ref) => StreakViewModel(ref.watch(streakRepositoryProvider)),
);
