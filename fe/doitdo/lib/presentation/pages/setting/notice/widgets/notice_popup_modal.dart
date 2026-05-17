import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/data/models/notice_dto.dart';
import 'package:doitdo/presentation/providers/app_data_providers.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_primary_button.dart';

/// 앱 첫 진입 시(기본 화면 로딩 후) 1 회 표시되는 공지 팝업 — 모던 스타일.
///
/// 디자인 키:
/// - 상단 아이콘 + 부드러운 강조 컬러 헤더
/// - 큼지막한 제목 + 작성일 보조 텍스트
/// - 스크롤 가능한 본문 (DraggableScrollableSheet)
/// - 하단 "다시 안보기" 인라인 체크 + 알약 CTA
///
/// 사용자가 "확인" 닫을 때:
/// - 토글 ON  → `POST /api/notices/{noticeId}/dismiss` 호출
/// - 토글 OFF → API 호출 없음
Future<void> showNoticePopupModal(
  BuildContext context, {
  required NoticeResp notice,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // 바깥 탭으로 닫지 못함 — "확인" 으로만 닫도록 유도
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (ctx) => _NoticePopupModal(notice: notice),
  );
}

class _NoticePopupModal extends ConsumerStatefulWidget {
  const _NoticePopupModal({required this.notice});

  final NoticeResp notice;

  @override
  ConsumerState<_NoticePopupModal> createState() => _NoticePopupModalState();
}

class _NoticePopupModalState extends ConsumerState<_NoticePopupModal> {
  bool _dontShowAgain = false;
  bool _submitting = false;

  Future<void> _close() async {
    if (_submitting) return;
    if (_dontShowAgain) {
      setState(() => _submitting = true);
      try {
        await ref
            .read(noticeRepositoryProvider)
            .dismissNotice(widget.notice.noticeId);
      } catch (_) {
        // 실패해도 사용자 흐름은 막지 않음 (다음 진입 시 자동 재시도 가능).
      }
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // 토스류 미니멀 톤: 구분선 없이 여백으로 영역 구분, 본문은 콤팩트하게.
    // showDialog 가 화면 중앙에 자동 배치.
    final screenHeight = MediaQuery.of(context).size.height;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          // 본문이 너무 길어도 화면의 65% 까지만. 토스류는 모달이 화면을 다 덮지 않음.
          maxHeight: screenHeight * 0.65,
        ),
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
          child: Column(
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
                        widget.notice.title,
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
              if (widget.notice.createdAt != null)
                Padding(
                  // 아이콘(32) + gap(10) 만큼 들여써서 제목 줄과 정렬 맞춤.
                  padding: EdgeInsets.fromLTRB(24.w + 32.w + 10.w, 4.h, 24.w, 0),
                  child: Text(
                    _formatDate(widget.notice.createdAt!),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: colors.textHint,
                    ),
                  ),
                ),
              SizedBox(height: 22.h),
              // ─── 스크롤 가능한 본문 영역 (구분선 없음, 여백으로 구분) ───
              Flexible(
                child: SingleChildScrollView(
                  // 본문 상하좌우 여백 — 카드 끝과 텍스트 사이 숨 쉴 공간 확보.
                  padding: EdgeInsets.fromLTRB(28.w, 4.h, 28.w, 10.h),
                  child: Text(
                    widget.notice.content,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: colors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 18.h),
              // ─── "설정에서 다시 볼 수 있다" 안내 문구 ───
              // 사용자가 "다시 안보기" 를 눌러도 영영 못 보는 게 아니라는 안심 메시지.
              // 작은 회색 톤으로 절제. 토스류의 보조 안내 톤 따라감.
              Padding(
                padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 10.h),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 12.sp,
                      color: colors.textHint,
                    ),
                    SizedBox(width: 4.w),
                    Flexible(
                      child: Text(
                        '설정 > 공지사항에서 다시 볼 수 있어요',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: colors.textHint,
                          fontSize: 11.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              // ─── 고정 하단 (체크 + CTA) ───
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 4.h),
                child: _DontShowAgainTile(
                  checked: _dontShowAgain,
                  onChanged: (v) {
                    HapticFeedback.selectionClick();
                    setState(() => _dontShowAgain = v);
                  },
                  colors: colors,
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 20.h),
                child: DoitdoPrimaryButton(
                  label: _submitting ? '닫는 중…' : '확인',
                  onPressed: _submitting ? null : _close,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ISO-8601 → "YYYY.MM.DD" 표시용. 파싱 실패 시 원문 반환.
  String _formatDate(String iso) {
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return iso;
    final y = parsed.year;
    final m = parsed.month.toString().padLeft(2, '0');
    final d = parsed.day.toString().padLeft(2, '0');
    return '$y.$m.$d';
  }
}


/// "다시 안보기" 인라인 체크박스 행 — 토글 대신 체크 박스 + 라벨 형태.
class _DontShowAgainTile extends StatelessWidget {
  const _DontShowAgainTile({
    required this.checked,
    required this.onChanged,
    required this.colors,
  });

  final bool checked;
  final ValueChanged<bool> onChanged;
  final DoitdoColors colors;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!checked),
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(
                color: checked ? colors.primary : Colors.transparent,
                border: Border.all(
                  color: checked ? colors.primary : colors.border,
                  width: 1.6,
                ),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: checked
                  ? Icon(
                      Icons.check_rounded,
                      size: 14.sp,
                      color: colors.onPrimary,
                    )
                  : null,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                '이 공지사항 다시 보지 않기',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: checked ? colors.textPrimary : colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
