import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/domain/entities/user.dart';
import 'package:doitdo/presentation/providers/app_data_providers.dart';

/// 회원가입 플로우 ViewModel.
///
/// `POST /api/auth/signup` 성공 후 **자동 로그인하지 않고** 로그인 화면으로
/// 돌아간다. 사용자에게 "가입됐으니 이제 로그인하세요" 라는 명시적인 단계를
/// 거치게 해서 실수로 잘못된 계정이 자동 로그인되는 일을 방지.
///
/// - 초기 상태: `AsyncData(null)` — 아직 제출 안 함
/// - 성공: `AsyncData(User)` — 서버가 돌려준 신규 유저 정보 (토큰 없음).
///   View 는 이 값으로 로그인 화면에 이메일/아이디를 미리 채우거나, 스낵바 문구에 사용.
/// - 실패: `AsyncError` — 스낵바
class RegisterViewModel extends AutoDisposeAsyncNotifier<User?> {
  @override
  Future<User?> build() async => null;

  Future<void> submit({
    required String email,
    required String password,
    required String username,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      return repo.signUp(
        email: email,
        password: password,
        username: username,
      );
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
