import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/core/errors/exceptions.dart';
import 'package:doitdo/domain/entities/user.dart';
import 'package:doitdo/presentation/providers/app_data_providers.dart';
import 'package:doitdo/presentation/providers/current_user_provider.dart';

/// 온보딩 1단계(생년월일) ViewModel.
///
/// - 초기: `AsyncData(null)` — 미시도
/// - 로딩: `AsyncLoading()` — 서버 호출 중
/// - 성공: `AsyncData(User)` — birthDateRegistered=true 로 갱신된 유저. View 가
///   2단계(약관) 라우트로 이동
/// - 실패:
///   - 만 14세 미만 → `ServerException(403)`. View 가 토큰 정리 후 Welcome 으로 이동.
///   - 그 외 → 스낵바
///
/// 가이드 §12.6 — 서버 호출이 있는 ViewModel 은 `AsyncNotifier`.
class OnboardingBirthDateViewModel extends AutoDisposeAsyncNotifier<User?> {
  @override
  Future<User?> build() async => null;

  Future<void> submit(DateTime birthDate) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(userRepositoryProvider);
      final user = await repo.registerBirthDate(birthDate);
      // 온보딩 진행 중에는 currentUserProvider 를 invalidate 하면 build() 가 다시 돌면서
      // 같은 GET /me 가 또 발생할 뿐이므로 invalidate 대신 직접 state 를 업데이트한다.
      _patchCurrentUser(user);
      return user;
    });
  }

  /// 만 14세 미만 hard delete 케이스인지 판정. View 가 분기에 사용.
  static bool isUnderageError(Object error) =>
      error is ServerException && error.statusCode == 403;

  void _patchCurrentUser(User user) {
    final notifier = ref.read(currentUserProvider.notifier);
    final current = ref.read(currentUserProvider).valueOrNull;
    notifier.replace(user.copyWith(
      // 토큰이 살아있는 동안은 hasPassword 가 바뀌지 않으므로 기존 값을 보존.
      hasPassword: current?.hasPassword ?? user.hasPassword,
    ));
  }
}

final onboardingBirthDateViewModelProvider =
    AsyncNotifierProvider.autoDispose<OnboardingBirthDateViewModel, User?>(
  OnboardingBirthDateViewModel.new,
);

// ────────────────────────────────────────────────────────────────────────────

/// 온보딩 2단계(약관 동의) View 가 들고 있는 체크박스 상태.
///
/// 마케팅은 선택이지만 필수 두 개(`termsAgreed`, `privacyAgreed`) 가 false 면
/// "동의하고 시작하기" 버튼을 비활성화해야 한다 — [canSubmit] 사용.
class AgreementsFormState {
  const AgreementsFormState({
    this.termsAgreed = false,
    this.privacyAgreed = false,
    this.marketingAgreed = false,
  });

  final bool termsAgreed;
  final bool privacyAgreed;
  final bool marketingAgreed;

  bool get allChecked => termsAgreed && privacyAgreed && marketingAgreed;
  bool get canSubmit => termsAgreed && privacyAgreed;

  AgreementsFormState copyWith({
    bool? termsAgreed,
    bool? privacyAgreed,
    bool? marketingAgreed,
  }) =>
      AgreementsFormState(
        termsAgreed: termsAgreed ?? this.termsAgreed,
        privacyAgreed: privacyAgreed ?? this.privacyAgreed,
        marketingAgreed: marketingAgreed ?? this.marketingAgreed,
      );
}

/// 약관 동의 폼 컨트롤러 (체크박스 토글 전용 — 서버 호출은 별도 ViewModel).
class AgreementsFormController extends AutoDisposeNotifier<AgreementsFormState> {
  @override
  AgreementsFormState build() => const AgreementsFormState();

  void setTerms(bool v) => state = state.copyWith(termsAgreed: v);
  void setPrivacy(bool v) => state = state.copyWith(privacyAgreed: v);
  void setMarketing(bool v) => state = state.copyWith(marketingAgreed: v);

  /// "전체 동의" 토글 — 모두 같은 값으로 세팅.
  void setAll(bool v) => state = AgreementsFormState(
        termsAgreed: v,
        privacyAgreed: v,
        marketingAgreed: v,
      );
}

final agreementsFormControllerProvider = NotifierProvider.autoDispose<
    AgreementsFormController, AgreementsFormState>(
  AgreementsFormController.new,
);

/// 온보딩 2단계(약관) — 실제 서버 호출 ViewModel.
///
/// 성공 시 갱신된 [User] (agreementsAccepted=true) 를 반환. View 가 메인 탭으로 이동.
class OnboardingAgreementsViewModel extends AutoDisposeAsyncNotifier<User?> {
  @override
  Future<User?> build() async => null;

  Future<void> submit({
    required bool termsAgreed,
    required bool privacyAgreed,
    required bool marketingAgreed,
  }) async {
    // 클라이언트단 가드 — ViewModel 이 잘못된 호출을 막아 서버 422 를 줄인다.
    if (!termsAgreed || !privacyAgreed) {
      state = AsyncValue.error(
        const ServerException('필수 약관에 동의해주세요.'),
        StackTrace.current,
      );
      return;
    }
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(userRepositoryProvider);
      final user = await repo.registerAgreements(
        termsAgreed: termsAgreed,
        privacyAgreed: privacyAgreed,
        marketingAgreed: marketingAgreed,
      );
      ref.read(currentUserProvider.notifier).replace(user.copyWith(
            hasPassword:
                ref.read(currentUserProvider).valueOrNull?.hasPassword ??
                    user.hasPassword,
          ));
      // 온보딩 완료 시점에 FCM 토큰 등록 — 이전 소셜 로그인 시에는 서버가 403으로 막았음.
      unawaited(ref.read(fcmTokenRegistrarProvider).register());
      return user;
    });
  }
}

final onboardingAgreementsViewModelProvider =
    AsyncNotifierProvider.autoDispose<OnboardingAgreementsViewModel, User?>(
  OnboardingAgreementsViewModel.new,
);
