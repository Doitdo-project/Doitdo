import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/presentation/providers/app_data_providers.dart';

/// 비밀번호 변경 다이얼로그 ViewModel.
///
/// 상태 타입은 `bool?`:
/// - `null`  : 초기 / 아직 제출 전
/// - `true`  : 변경 성공 (View 가 다이얼로그 pop + 스낵바)
/// - error   : 변경 실패 (현재 비밀번호 불일치 등) — 스낵바
///
/// `void` 로 두지 않는 이유: `AccountViewModel.signOut` 과 동일하게, 초기 build
/// 시점의 `Loading → Data(null)` 전이가 성공으로 오인되는 버그 방지.
class PasswordChangeViewModel extends AutoDisposeAsyncNotifier<bool?> {
  @override
  Future<bool?> build() async => null;

  Future<void> submit({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(userRepositoryProvider).changePassword(
            currentPassword: currentPassword,
            newPassword: newPassword,
          );
      return true;
    });
  }
}

final passwordChangeViewModelProvider =
    AsyncNotifierProvider.autoDispose<PasswordChangeViewModel, bool?>(
  PasswordChangeViewModel.new,
);
