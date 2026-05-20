import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/presentation/pages/setting/notice/widgets/notice_popup_modal.dart';
import 'package:doitdo/presentation/providers/app_data_providers.dart';
import 'package:doitdo/presentation/providers/default_screen_provider.dart';
import 'package:doitdo/presentation/providers/notice_providers.dart';

/// 사용자의 "기본 화면" 진입 시 1 회 공지 팝업 띄우기.
///
/// 호출 위치:
/// - [tamagochi_page] : `forScreen = DefaultScreen.home` 으로 호출
/// - [todo_page]      : `forScreen = DefaultScreen.calendar` 으로 호출
///
/// 동작:
/// - 사용자가 설정한 기본 화면이 [forScreen] 과 다르면 아무 일도 안 함
/// - 같은 앱 세션에서 이미 1 회 표시됐으면 스킵
/// - 그 외엔 `GET /api/notices/latest-popup` 호출 → show=true 면 모달 띄움
///
/// 실패 시 세션 플래그를 리셋해 다음 진입에서 재시도 가능하게 한다.
Future<void> maybeShowNoticePopup(
  BuildContext context,
  WidgetRef ref, {
  required DefaultScreen forScreen,
}) async {
  final defaultScreen = ref.read(defaultScreenProvider);
  if (defaultScreen != forScreen) return;

  final shown = ref.read(latestPopupShownThisSessionProvider);
  if (shown) return;

  // 중복 트리거 방지: API 호출 전에 먼저 플래그를 올린다.
  // 실패 시에만 리셋해서 재시도 가능하게.
  ref.read(latestPopupShownThisSessionProvider.notifier).markShown();

  try {
    final resp = await ref.read(noticeRepositoryProvider).getLatestPopup();
    if (!context.mounted) return;
    final notice = resp.notice;
    if (resp.show && notice != null) {
      await showNoticePopupModal(context, notice: notice);
    }
  } catch (_) {
    // 실패: 다음 진입 때 재시도 가능하게 플래그 복구
    ref.read(latestPopupShownThisSessionProvider.notifier).reset();
  }
}
