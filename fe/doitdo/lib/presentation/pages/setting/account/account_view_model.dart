import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/presentation/providers/app_data_providers.dart';

/// 계정 설정 화면에서 수행되는 사이드이펙트(로그아웃 등) 를 관리.
///
/// 상태 타입은 **`bool?`** 로 정의해 "초기 진입" 과 "signOut 성공" 을 구분한다:
/// - `null`  : 초기 / 아직 signOut 호출 전
/// - `true`  : signOut 성공 (View 가 welcome 으로 이동)
/// - error   : signOut 실패 (스낵바)
///
/// `void` 로 두면 초기 build 시점의 `Loading → Data(null)` 전이도
/// "성공" 으로 오인돼 페이지 진입 즉시 welcome 으로 튕기는 버그 발생.
///
/// 가이드 §12.6 — 서버 호출 ViewModel 은 `AsyncNotifier`.
class AccountViewModel extends AutoDisposeAsyncNotifier<bool?> {
  @override
  Future<bool?> build() async => null;

  /// 로그아웃 — 서버 세션 종료 + 로컬 토큰 삭제 + 소셜 SDK 세션 해제.
  /// 성공 시 `true` 로 상태 전환 → View 의 `ref.listen` 이 감지해 welcome 이동.
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).signOut();
      return true;
    });
  }
}

final accountViewModelProvider =
    AsyncNotifierProvider.autoDispose<AccountViewModel, bool?>(
  AccountViewModel.new,
);
