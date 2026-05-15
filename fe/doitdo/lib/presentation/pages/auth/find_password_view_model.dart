import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/presentation/providers/app_data_providers.dart';

/// 비밀번호 찾기 (재설정) 1·2단계 ViewModel.
///
/// Page 가 단일 위젯 안에서 step 1↔2 를 전환하는 구조라 두 단계를 한 notifier 에
/// 묶었다. 3단계(새 비밀번호 입력)는 별도 라우트(`ResetPasswordPage`)라서 별도
/// ViewModel 로 분리되어 있다.
///
/// 상태는 [FindPasswordPhase] sealed — `Idle / CodeSent / Verified` 로 진행 단계와
/// 검증 성공 시 받은 1회용 `resetToken` 을 모두 담는다. Page 는 `Verified` 진입 시
/// 그 토큰을 들고 다음 화면으로 이동한다.
class FindPasswordViewModel extends AutoDisposeAsyncNotifier<FindPasswordPhase> {
  @override
  Future<FindPasswordPhase> build() async => const FindPasswordIdle();

  /// 1단계 — 이메일로 인증번호 발송.
  Future<void> sendCode(String email) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).requestPasswordResetCode(email);
      return FindPasswordCodeSent(email: email);
    });
  }

  /// "이메일 다시 입력하기" 등으로 step 1 로 되돌릴 때 호출.
  /// AsyncError 상태일 때도 idle 로 비워서 인라인 에러 잔여물을 정리한다.
  void resetToIdle() {
    state = const AsyncValue.data(FindPasswordIdle());
  }

  /// 2단계 — 인증번호 검증. 1단계에서 저장한 이메일을 그대로 사용한다.
  /// 검증 성공 시 [FindPasswordVerified] 로 전이하며 1회용 `resetToken` 을 보관.
  Future<void> verifyCode(String code) async {
    final current = state.valueOrNull;
    if (current is! FindPasswordCodeSent) {
      // 이론적으로 도달 불가 — Page 가 step 2 에서만 호출.
      throw StateError('verifyCode 는 인증번호 발송 이후에만 호출할 수 있어요.');
    }
    final email = current.email;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final resetToken = await ref
          .read(authRepositoryProvider)
          .verifyPasswordResetCode(email: email, code: code);
      return FindPasswordVerified(email: email, resetToken: resetToken);
    });
  }
}

/// 비밀번호 찾기 흐름의 단계별 상태.
sealed class FindPasswordPhase {
  const FindPasswordPhase();
}

class FindPasswordIdle extends FindPasswordPhase {
  const FindPasswordIdle();
}

class FindPasswordCodeSent extends FindPasswordPhase {
  const FindPasswordCodeSent({required this.email});
  final String email;
}

class FindPasswordVerified extends FindPasswordPhase {
  const FindPasswordVerified({required this.email, required this.resetToken});
  final String email;
  final String resetToken;
}

final findPasswordViewModelProvider = AsyncNotifierProvider.autoDispose<
    FindPasswordViewModel, FindPasswordPhase>(FindPasswordViewModel.new);
