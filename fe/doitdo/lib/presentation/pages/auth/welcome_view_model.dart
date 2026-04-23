import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/presentation/providers/app_data_providers.dart';

/// 소셜 로그인 성공 시 전달되는 요약 데이터.
///
/// View 에서 이 값을 보고:
/// - `isNewUser == true` → 온보딩/추가 정보 입력 화면으로
/// - `isNewUser == false` → 메인 탭으로
/// 분기할 수 있도록 한다.
class WelcomeSuccess {
  const WelcomeSuccess({required this.isNewUser});
  final bool isNewUser;
}

/// Welcome 페이지의 소셜 로그인 ViewModel.
///
/// DEVELOPMENT_GUIDE §12.6 에 따라 서버 호출이 있는 ViewModel 은 `AsyncNotifier`.
/// Repository 가 throw 하는 타입드 예외는 [AsyncValue.guard] 가 그대로 잡아
/// `state.error` 로 흘려보내고, View 는 `ref.listen` 으로 성공/에러 부수효과만 처리.
///
/// - 초기 상태: `AsyncData(null)` — 아직 로그인 시도 없음
/// - 로딩: `AsyncLoading()`
/// - 성공: `AsyncData(WelcomeSuccess)` — 자동으로 메인 화면으로 라우팅
/// - 실패: `AsyncError` — 화면에서 스낵바
class WelcomeViewModel
    extends AutoDisposeAsyncNotifier<WelcomeSuccess?> {
  @override
  Future<WelcomeSuccess?> build() async => null;

  /// Google OAuth 수행. 결과는 state 로만 노출 (반환값 없음).
  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      final (_, __, isNewUser) = await repo.signInWithGoogle();
      return WelcomeSuccess(isNewUser: isNewUser);
    });
  }

  /// Kakao OAuth 수행. 규약은 [signInWithGoogle] 과 동일.
  Future<void> signInWithKakao() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      final (_, __, isNewUser) = await repo.signInWithKakao();
      return WelcomeSuccess(isNewUser: isNewUser);
    });
  }
}

final welcomeViewModelProvider =
    AsyncNotifierProvider.autoDispose<WelcomeViewModel, WelcomeSuccess?>(
  WelcomeViewModel.new,
);
