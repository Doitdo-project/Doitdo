import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/core/errors/exceptions.dart';
import 'package:doitdo/domain/entities/user.dart';
import 'package:doitdo/presentation/providers/app_data_providers.dart';

/// 앱 전역 "현재 로그인된 사용자" 상태.
///
/// - 초기 build() 에서 secure storage 의 토큰 존재 여부를 확인한 뒤, 토큰이 있으면
///   `GET /api/users/me` 로 최신 프로필을 가져온다. 토큰이 없으면 `null` 로 즉시 종료.
/// - 로그인 직후 / 회원가입 직후: View 에서 `ref.invalidate(currentUserProvider)`
///   로 강제 재조회.
/// - 로그아웃 후: 마찬가지로 invalidate. 토큰이 사라져서 `build()` 는 `null` 반환.
///
/// `AutoDispose` 가 아닌 [AsyncNotifier] 로 둬서 설정 ↔ 홈 간 이동에도 캐시 유지.
class CurrentUserViewModel extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    final tokens = await ref.read(authLocalDataSourceProvider).read();
    if (tokens == null) return null;

    try {
      return await ref.read(userRepositoryProvider).getMe();
    } on UnauthorizedException {
      // refresh 까지 실패한 상태 — 로컬 세션은 이미 AuthInterceptor 가 정리했을 것.
      return null;
    }
  }

  /// 로그인/회원가입 완료 후 호출해 최신 프로필로 싱크.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final tokens = await ref.read(authLocalDataSourceProvider).read();
      if (tokens == null) return null;
      return ref.read(userRepositoryProvider).getMe();
    });
  }
}

final currentUserProvider =
    AsyncNotifierProvider<CurrentUserViewModel, User?>(CurrentUserViewModel.new);
