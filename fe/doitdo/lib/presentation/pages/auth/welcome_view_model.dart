import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/core/errors/exceptions.dart';
import 'package:doitdo/domain/repositories/auth_repository.dart';
import 'package:doitdo/presentation/providers/app_data_providers.dart';

/// Welcome 페이지의 소셜 로그인 동작을 관리하는 ViewModel.
///
/// View 는 이 ViewModel 의 메서드만 호출하고, 성공/실패 결과에 따라 라우팅만 결정한다.
class WelcomeState {
  const WelcomeState({this.isLoading = false, this.error});

  final bool isLoading;
  final String? error;

  WelcomeState copyWith({bool? isLoading, String? error}) => WelcomeState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class WelcomeViewModel extends StateNotifier<WelcomeState> {
  WelcomeViewModel(this._authRepository) : super(const WelcomeState());

  final AuthRepository _authRepository;

  /// Google 로그인 수행.
  /// - 성공: true 반환, View 가 메인 화면으로 이동.
  /// - 사용자 취소: false 반환, state.error 는 null (조용히 처리).
  /// - 실패: false 반환, state.error 에 사용자에게 보여줄 메시지.
  Future<bool> signInWithGoogle() {
    return _runSocialSignIn(_authRepository.signInWithGoogle);
  }

  /// Kakao 로그인 수행. 반환/상태 규약은 [signInWithGoogle] 과 동일.
  Future<bool> signInWithKakao() {
    return _runSocialSignIn(_authRepository.signInWithKakao);
  }

  /// Google/Kakao 모두 상태 머신(로딩 → 성공/취소/실패) 이 동일하므로 한 곳으로 모은다.
  /// provider 별로 달라지는 건 실제로 호출하는 Repository 메서드 뿐.
  Future<bool> _runSocialSignIn(Future<Object?> Function() signIn) async {
    if (state.isLoading) return false;
    state = state.copyWith(isLoading: true, error: null);

    try {
      await signIn();
      state = state.copyWith(isLoading: false);
      return true;
    } on AuthCanceledException {
      // 사용자가 시트를 닫은 경우엔 에러 메시지 안 띄움.
      state = state.copyWith(isLoading: false);
      return false;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: '로그인 중 알 수 없는 오류가 발생했어요.',
      );
      return false;
    }
  }
}

final welcomeViewModelProvider =
    StateNotifierProvider.autoDispose<WelcomeViewModel, WelcomeState>(
  (ref) => WelcomeViewModel(ref.watch(authRepositoryProvider)),
);
