import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/data/models/notice_dto.dart';
import 'package:doitdo/presentation/providers/app_data_providers.dart';

/// 공지사항 목록 (설정 > 공지사항 화면용).
///
/// FutureProvider 로 한 번 받아 캐시. 사용자가 뒤로 갔다 돌아와도 재조회 안 함.
/// 새 공지가 올라온 게 명확한 케이스(예: 상세 화면 새로고침)에서 invalidate.
final noticeListProvider = FutureProvider<List<NoticeResp>>((ref) {
  return ref.read(noticeRepositoryProvider).getNotices();
});

/// 단건 공지 상세.
///
/// `family` 로 noticeId 별로 캐시. 같은 id 재조회 안 함.
final noticeDetailProvider =
    FutureProvider.family<NoticeResp, int>((ref, noticeId) {
  return ref.read(noticeRepositoryProvider).getNotice(noticeId);
});

/// 초기 진입 팝업 공지 + show 플래그.
///
/// 사용자가 "다시 안보기" 안 한 최신 공지가 있으면 [LatestPopupResp.show] = true.
/// 모달을 띄운 직후 [latestPopupShownThisSessionProvider] 를 true 로 갱신해
/// 같은 세션에서 다시 안 뜨도록 한다.
final latestPopupProvider = FutureProvider<LatestPopupResp>((ref) {
  return ref.read(noticeRepositoryProvider).getLatestPopup();
});

/// 이번 앱 세션에서 이미 팝업을 띄웠는지.
///
/// 같은 세션 안에서 "기본 화면" 으로 여러 번 진입(예: 탭 전환) 해도 팝업이 한 번만
/// 뜨게 한다. 앱 재시작하면 다시 false 로 시작.
class LatestPopupShownNotifier extends StateNotifier<bool> {
  LatestPopupShownNotifier() : super(false);

  void markShown() => state = true;

  /// 로그아웃 같은 세션 전환 지점에서 리셋.
  void reset() => state = false;
}

final latestPopupShownThisSessionProvider =
    StateNotifierProvider<LatestPopupShownNotifier, bool>(
        (ref) => LatestPopupShownNotifier());
