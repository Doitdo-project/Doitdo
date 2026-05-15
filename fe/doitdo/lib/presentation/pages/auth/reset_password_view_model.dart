import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/presentation/providers/app_data_providers.dart';

/// 비밀번호 재설정 마지막 단계 ViewModel.
///
/// `resetToken` 은 호출측이 [FindPasswordPage] 인증번호 검증 단계에서 발급받아
/// 라우트 extra 로 [ResetPasswordPage] 에 전달한다.
///
/// 상태 타입은 `bool?` ([PasswordChangeViewModel] 패턴과 동일):
/// - `null`  : 초기 / 아직 제출 전
/// - `true`  : 변경 성공 (View 가 로그인 화면 이동 + 스낵바)
/// - error   : 실패 (만료된 토큰 등) — 인라인 에러 노출
class ResetPasswordViewModel extends AutoDisposeAsyncNotifier<bool?> {
  @override
  Future<bool?> build() async => null;

  Future<void> submit({
    required String resetToken,
    required String newPassword,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).confirmPasswordReset(
            resetToken: resetToken,
            newPassword: newPassword,
          );
      return true;
    });
  }
}

final resetPasswordViewModelProvider =
    AsyncNotifierProvider.autoDispose<ResetPasswordViewModel, bool?>(
  ResetPasswordViewModel.new,
);
