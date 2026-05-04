import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/core/errors/exceptions.dart';
import 'package:doitdo/core/utils/error_message_mapper.dart';
import 'package:doitdo/domain/entities/user.dart';
import 'package:doitdo/presentation/providers/app_data_providers.dart';
import 'package:doitdo/presentation/providers/current_user_provider.dart';

/// 회원가입 플로우 ViewModel.
///
/// `POST /api/auth/signup` 은 토큰을 반환하지 않기 때문에, 성공 직후 곧바로
/// `POST /api/auth/login` 을 이어서 호출해 세션을 얻는다. View 는 최종적으로
/// 발급된 [User] 만 보면 된다.
///
/// - 초기 상태: `AsyncData(null)` — 아직 제출 안 함
/// - 성공: `AsyncData(User)` — 가입 + 로그인 완료, View 가 메인 탭으로 이동
/// - 실패: `AsyncError` — 스낵바
class RegisterViewModel extends AutoDisposeAsyncNotifier<User?> {
  @override
  Future<User?> build() async => null;

  Future<void> submit({
    required String email,
    required String password,
    required String username,
  }) async {
    if (state.isLoading) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      // 1) 회원가입 — 응답에 토큰 없음 (스펙상 userId/username/email 만).
      await repo.signUp(email: email, password: password, username: username);
      // 2) 이어서 바로 로그인 → access/refresh 토큰 발급 + secure storage 저장.
      //    가입 직후 같은 자격증명으로 로그인하므로 서버가 거부할 이유 없음.
      final (user, _) = await repo.signInWithEmail(
        username: username,
        password: password,
      );
      // 가입 + 자동 로그인 직후 전역 currentUserProvider 무효화.
      ref.invalidate(currentUserProvider);
      return user;
    });
  }
}

final registerViewModelProvider =
AsyncNotifierProvider.autoDispose<RegisterViewModel, User?>(
  RegisterViewModel.new,
);

// ─── 이메일 중복 체크 ─────────────────────────────────────────────

/// `GET /api/users/check-email` 결과 추적.
///
/// - `data == null`  : 아직 검사 안 함 (초기/빈값)
/// - `data == true`  : 사용 가능 (미등록)
/// - `data == false` : 이미 등록됨
/// - `loading`       : 검사 중
/// - `error`         : 네트워크/서버 오류
///
/// 가이드 §12.6 AsyncNotifier 패턴.
class EmailAvailabilityViewModel extends AutoDisposeAsyncNotifier<bool?> {
  @override
  Future<bool?> build() async => null;

  Future<void> check(String email) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
          () => ref.read(userRepositoryProvider).isEmailAvailable(email),
    );
  }

  /// 입력값이 유효하지 않아 검사를 생략할 때 상태를 초기화.
  void clear() {
    state = const AsyncValue.data(null);
  }
}

final emailAvailabilityProvider = AsyncNotifierProvider.autoDispose<
    EmailAvailabilityViewModel, bool?>(EmailAvailabilityViewModel.new);

// ─── 닉네임(username) 중복 체크 ────────────────────────────────────

class UsernameAvailabilityViewModel extends AutoDisposeAsyncNotifier<bool?> {
  @override
  Future<bool?> build() async => null;

  Future<void> check(String username) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
          () => ref.read(userRepositoryProvider).isUsernameAvailable(username),
    );
  }

  void clear() {
    state = const AsyncValue.data(null);
  }
}

final usernameAvailabilityProvider = AsyncNotifierProvider.autoDispose<
    UsernameAvailabilityViewModel, bool?>(UsernameAvailabilityViewModel.new);

/// 회원가입 실패 메시지를 화면 맥락에 맞게 반환.
///
/// 공용 [mapErrorMessage] 와 달리 409/422 를 회원가입 맥락으로 해석.
/// - 409: 중복 체크를 통과했더라도 타이밍 이슈로 제출 시점에 중복이 생길 수 있음.
/// - 422: 서버 유효성 검사 실패 — 한국어 메시지면 그대로, 아니면 공용 문구.
/// 나머지는 공용 [mapErrorMessage] 에 위임.
String mapRegisterErrorMessage(Object error) {
  if (error is ServerException) {
    final code = error.statusCode ?? 0;
    final isKorean = RegExp(r'[가-힣]').hasMatch(error.message);

    if (code == 409) {
      return (error.message.isNotEmpty && isKorean)
          ? error.message
          : '이미 사용 중인 아이디 또는 이메일이에요.';
    }
    if (code == 422) {
      return (error.message.isNotEmpty && isKorean)
          ? error.message
          : '입력하신 내용을 다시 확인해 주세요.';
    }
  }
  return mapErrorMessage(error);
}