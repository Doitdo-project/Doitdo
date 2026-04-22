import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/domain/repositories/auth_repository.dart';
import 'package:doitdo/presentation/providers/app_data_providers.dart';

/// 계정 설정 화면에서 수행되는 사이드이펙트(로그아웃 등) 를 관리.
///
/// 추후 "회원탈퇴 / 비밀번호 변경 / 소셜 계정 연동·해제" 가 이 ViewModel 에 합류할 예정.
class AccountState {
  const AccountState({this.isLoading = false, this.error});

  final bool isLoading;
  final String? error;

  AccountState copyWith({bool? isLoading, String? error}) => AccountState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class AccountViewModel extends StateNotifier<AccountState> {
  AccountViewModel(this._authRepository) : super(const AccountState());

  final AuthRepository _authRepository;

  /// 로그아웃 수행.
  /// - 성공: true 반환. View 는 welcome 으로 이동.
  /// - 실패: false, `state.error` 에 사용자에게 보여줄 메시지.
  Future<bool> signOut() async {
    if (state.isLoading) return false;
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authRepository.signOut();
      state = state.copyWith(isLoading: false);
      return true;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: '로그아웃 중 오류가 발생했어요.',
      );
      return false;
    }
  }
}

final accountViewModelProvider =
    StateNotifierProvider.autoDispose<AccountViewModel, AccountState>(
  (ref) => AccountViewModel(ref.watch(authRepositoryProvider)),
);
