import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/presentation/providers/app_data_providers.dart';

/// 계정 설정 화면에서 수행되는 사이드이펙트(로그아웃 등) 를 관리.
///
/// 가이드 §12.6 — 서버 호출이 있는 ViewModel 은 `AsyncNotifier`.
/// - 초기 상태: `AsyncData(null)`
/// - 로딩: `AsyncLoading()` — 로그아웃 진행 중
/// - 성공: `AsyncData(null)` — View 는 `ref.listen` 으로 prev==loading 전이 감지해 웰컴 이동
/// - 실패: `AsyncError` — 스낵바
///
/// 추후 "회원탈퇴 / 비밀번호 변경 / 소셜 계정 연동·해제" 가 여기에 합류할 예정.
/// 각각 별도 메서드로 추가하면 `state` 를 공유한다.
class AccountViewModel extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// 로그아웃 — 서버 세션 종료 + 로컬 토큰 삭제 + 소셜 SDK 세션 해제.
  /// Repository 가 내부적으로 "서버 실패해도 로컬은 정리" 하는 정책이라
  /// 대부분 success 로 완료되지만, 그래도 타입드 예외는 AsyncValue.guard 가 잡는다.
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signOut(),
    );
  }
}

final accountViewModelProvider =
    AsyncNotifierProvider.autoDispose<AccountViewModel, void>(
  AccountViewModel.new,
);
