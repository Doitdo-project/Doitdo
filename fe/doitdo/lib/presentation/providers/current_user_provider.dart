import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/core/errors/exceptions.dart';
import 'package:doitdo/domain/entities/user.dart';
import 'package:doitdo/presentation/providers/app_data_providers.dart';

/// 현재 로그인한 사용자 상태.
///
/// - 초기 build()에서 secure storage의 토큰을 확인하고, 토큰이 있으면
///   `GET /api/users/me`로 최신 프로필을 가져온다.
/// - 로그인/온보딩처럼 이미 서버 응답으로 [User]를 받은 경우에는 [replace]로
///   캐시를 갱신해 추가 GET 호출을 피한다.
/// - 로그아웃/회원탈퇴처럼 토큰이 사라지는 흐름에서는 provider를 invalidate한다.
class CurrentUserViewModel extends AsyncNotifier<User?> {
  Future<User?>? _getMeInFlight;

  @override
  Future<User?> build() {
    return _getMeOnce();
  }

  /// 최신 프로필로 동기화한다.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_getMeOnce);
  }

  Future<User?> _getMeOnce() {
    final inFlight = _getMeInFlight;
    if (inFlight != null) return inFlight;

    final future = _fetchCurrentUser().whenComplete(() {
      _getMeInFlight = null;
    });
    _getMeInFlight = future;
    return future;
  }

  Future<User?> _fetchCurrentUser() async {
    final tokens = await ref.read(authLocalDataSourceProvider).read();
    if (tokens == null) return null;

    try {
      return await ref.read(userRepositoryProvider).getMe();
    } on UnauthorizedException {
      // AuthInterceptor handles failed refresh/logout cleanup.
      return null;
    }
  }

  /// 서버 응답으로 이미 받은 [User]를 캐시에 바로 반영한다.
  void replace(User? user) {
    _getMeInFlight = null;
    state = AsyncValue.data(user);
  }
}

final currentUserProvider = AsyncNotifierProvider<CurrentUserViewModel, User?>(
  CurrentUserViewModel.new,
);
