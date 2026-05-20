import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/data/models/notice_dto.dart';
import 'package:doitdo/presentation/providers/notice_providers.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_primary_button.dart';

/// 설정 > 공지사항 목록에서 항목 탭 시 열리는 상세 모달.
///
/// 초기 진입 팝업(`notice_popup_modal.dart`) 과 동일한 카드형 중앙 모달 UI 사용.
/// 차이점: "다시 안보기" 토글이 없고, 항상 볼 수 있는 읽기 전용 모달.
///
/// 함수 이름은 (외부 호출처와 호환을 위해) 기존 `showNoticeDetailSheet` 유지.
Future<void> showNoticeDetailSheet(
  BuildContext context, {
  required int noticeId,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (_) => _NoticeDetailModal(noticeId: noticeId),
  );
}

class _NoticeDetailModal extends ConsumerWidget {
  const _NoticeDetailModal({required this.noticeId});

  final int noticeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final screenHeight = MediaQuery.of(context).size.height;
    final async = ref.watch(noticeDetailProvider(noticeId));

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: screenHeight * 0.65),
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: async.when(
            loading: () => SizedBox(
              height: 200.h,
              child: const Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => _ErrorView(
              colors: colors,
              onClose: () => Navigator.of(context).pop(),
            ),
            data: (notice) => _DetailContent(
              notice: notice,
              colors: colors,
              onClose: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({
    required this.notice,
    required this.colors,
    required this.onClose,
  });

  final NoticeResp notice;
  final DoitdoColors colors;
  final VoidCallback onClose;

  String _formatDate(String iso) {
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return iso;
    final y = parsed.year;
    final m = parsed.month.toString().padLeft(2, '0');
    final d = parsed.day.toString().padLeft(2, '0');
    return '$y.$m.$d';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ─── 고정 헤더 (아이콘 + 제목) ───
        Padding(
          padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 32.w,
                height: 32.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.primary.withValues(alpha: 0.12),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.campaign_rounded,
                  color: colors.primary,
                  size: 18.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  notice.title,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: colors.textPrimary,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (notice.createdAt != null)
          Padding(
            padding: EdgeInsets.fromLTRB(24.w + 32.w + 10.w, 4.h, 24.w, 0),
            child: Text(
              _formatDate(notice.createdAt!),
              style: AppTextStyles.bodySmall.copyWith(
                color: colors.textHint,
              ),
            ),
          ),
        SizedBox(height: 22.h),
        // ─── 스크롤 가능한 본문 영역 ───
        Flexible(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(28.w, 4.h, 28.w, 10.h),
            child: Text(
              notice.content,
              style: AppTextStyles.bodyMedium.copyWith(
                color: colors.textSecondary,
                height: 1.6,
              ),
            ),
          ),
        ),
        SizedBox(height: 18.h),
        // ─── 닫기 버튼 (다시 안보기 없음 — 단순 읽기 모달) ───
        Padding(
          padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
          child: DoitdoPrimaryButton(
            label: '확인',
            onPressed: onClose,
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.colors, required this.onClose});

  final DoitdoColors colors;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 20.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded,
              color: colors.textHint, size: 32.sp),
          SizedBox(height: 12.h),
          Text(
            '공지사항을 불러오지 못했어요.',
            style: AppTextStyles.bodyMedium.copyWith(color: colors.textHint),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20.h),
          DoitdoPrimaryButton(label: '확인', onPressed: onClose),
        ],
      ),
    );
  }
}
