import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/domain/entities/user.dart';
import 'package:doitdo/presentation/providers/app_data_providers.dart';
import 'package:doitdo/presentation/providers/current_user_provider.dart';

/// 소셜 로그인 성공 시 전달되는 요약 데이터.
///
/// View 에서 이 값을 보고 분기:
/// - 온보딩 미완료([User.isOnboardingComplete]==false) → 온보딩 화면으로
/// - 완료 → 메인 탭으로
///
/// `isNewUser` 는 서버가 내려주는 "이번 호출이 신규 계정 생성인가?" 플래그.
/// 온보딩 분기엔 불필요(서버의 birthDateRegistered/agreementsAccepted 가 더 정확) 하지만,
/// 추후 환영 토스트 등 분기에 사용할 수 있어 그대로 보존.
class WelcomeSuccess {
  const WelcomeSuccess({required this.user, required this.isNewUser});
  final User user;
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
/// - 성공: `AsyncData(WelcomeSuccess)` — View 가 `user` 의 온보딩 플래그를 보고 라우팅
/// - 실패: `AsyncError` — 화면에서 스낵바
class WelcomeViewModel
    extends AutoDisposeAsyncNotifier<WelcomeSuccess?> {
  @override
  Future<WelcomeSuccess?> build() async => null;

  /// Google OAuth 수행. 결과는 state 로만 노출 (반환값 없음).
  /// 성공 시 currentUserProvider 도 응답으로 받은 user 로 즉시 동기화 (추가 GET 호출 안 발생).
  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      final (user, _, isNewUser) = await repo.signInWithGoogle();
      ref.read(currentUserProvider.notifier).replace(user);
      // FCM 토큰 등록은 비동기 부수효과 — 실패해도 로그인 흐름을 막지 않는다.
      unawaited(ref.read(fcmTokenRegistrarProvider).register());
      return WelcomeSuccess(user: user, isNewUser: isNewUser);
    });
  }

  /// Kakao OAuth 수행. 규약은 [signInWithGoogle] 과 동일.
  Future<void> signInWithKakao() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      final (user, _, isNewUser) = await repo.signInWithKakao();
      ref.read(currentUserProvider.notifier).replace(user);
      unawaited(ref.read(fcmTokenRegistrarProvider).register());
      return WelcomeSuccess(user: user, isNewUser: isNewUser);
    });
  }

  /// Apple Sign-In 수행. 규약은 [signInWithGoogle] 과 동일.
  Future<void> signInWithApple() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      final (user, _, isNewUser) = await repo.signInWithApple();
      ref.read(currentUserProvider.notifier).replace(user);
      return WelcomeSuccess(user: user, isNewUser: isNewUser);
    });
  }
}

final welcomeViewModelProvider =
    AsyncNotifierProvider.autoDispose<WelcomeViewModel, WelcomeSuccess?>(
  WelcomeViewModel.new,
);
