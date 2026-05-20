import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/core/errors/exceptions.dart';
import 'package:doitdo/domain/entities/user.dart';
import 'package:doitdo/presentation/providers/app_data_providers.dart';
import 'package:doitdo/presentation/providers/current_user_provider.dart';
import 'package:doitdo/presentation/pages/tamagochi/character_view_model.dart';

/// 이메일(실제는 username) + 비밀번호 로그인 ViewModel.
///
/// 가이드 §12.6 — 서버 호출이 있는 ViewModel 은 `AsyncNotifier`.
/// Repository 가 throw 하는 타입드 예외는 [AsyncValue.guard] 가 잡아
/// `state.error` 로 흘려보내고, View 는 `ref.listen` 으로 성공/에러 부수효과만 처리.
///
/// - 초기 상태: `AsyncData(null)` — 아직 로그인 시도 없음
/// - 로딩: `AsyncLoading()`
/// - 성공: `AsyncData(User)` — View 가 메인으로 라우팅
/// - 실패: `AsyncError` — 스낵바 노출
class LoginViewModel extends AutoDisposeAsyncNotifier<User?> {
  @override
  Future<User?> build() async => null;

  Future<void> signIn({
    required String username,
    required String password,
  }) async {
    if (state.isLoading) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      final (user, _) = await repo.signInWithEmail(
        username: username,
        password: password,
      );
      // 로그인 응답에 포함된 user를 바로 반영해 추가 GET /api/users/me를 피한다.
      ref.read(currentUserProvider.notifier).replace(user);
      // 캘린더를 기본화면으로 설정한 경우에도 캐릭터 이미지가 처음부터
      // 표시되도록 로그인 직후 미리 로드. 라우팅을 막지 않는 fire-and-forget.
      unawaited(ref.read(characterViewModelProvider.notifier).load());
      unawaited(ref.read(fcmTokenRegistrarProvider).register());
      return user;
    });
  }

  /// 사용자가 필드를 다시 입력하기 시작하면 이전 실패 메시지를 지운다.
  /// View 에서 controller.addListener 로 호출.
  void clearError() {
    if (state.hasError) {
      state = const AsyncValue.data(null);
    }
  }
}

/// 로그인 실패 메시지를 화면 맥락에 맞게 반환.
///
/// 일반 [mapErrorMessage] 와 달리 `UnauthorizedException` / `ServerException(401)` 를
/// "아이디/비밀번호 불일치" 로 해석 — 로그인 화면에선 세션 만료가 아니라
/// 사용자가 막 시도하는 인증 실패이기 때문.
String mapLoginErrorMessage(Object error) {
  if (error is UnauthorizedException) {
    return '아이디 또는 비밀번호가 일치하지 않아요.';
  }
  if (error is ServerException) {
    final code = error.statusCode ?? 0;
    if (code == 400 || code == 401) {
      return '아이디 또는 비밀번호가 일치하지 않아요.';
    }
    if (code >= 500) {
      return '서버 오류가 발생했어요. 잠시 후 다시 시도해 주세요.';
    }
    return error.message;
  }
  if (error is NetworkException) return '네트워크 연결을 확인해 주세요.';
  if (error is RequestTimeoutException) {
    return '응답이 지연되고 있어요. 잠시 후 다시 시도해 주세요.';
  }
  return '로그인에 실패했어요. 잠시 후 다시 시도해 주세요.';
}

final loginViewModelProvider =
    AsyncNotifierProvider.autoDispose<LoginViewModel, User?>(
      LoginViewModel.new,
    );
