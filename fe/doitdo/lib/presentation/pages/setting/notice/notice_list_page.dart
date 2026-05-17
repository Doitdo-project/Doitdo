import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/data/models/notice_dto.dart';
import 'package:doitdo/presentation/pages/setting/notice/widgets/notice_detail_sheet.dart';
import 'package:doitdo/presentation/providers/notice_providers.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_top_bar.dart';
import 'package:doitdo/presentation/widgets/layouts/doitdo_padding_layout.dart';
import 'package:doitdo/presentation/widgets/layouts/doitdo_scaffold.dart';

/// 설정 > 공지사항 목록 페이지.
///
/// 활성 공지사항 전체를 최신순으로 표시. 항목 탭 시 [showNoticeDetailSheet] 로
/// 상세 시트 표시. 사용자가 "다시 안보기" 한 공지도 여기서는 정상 노출.
class NoticeListPage extends ConsumerWidget {
  const NoticeListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final async = ref.watch(noticeListProvider);

    return DoitdoScaffold(
      topBar: const DoitdoTopBar(title: '공지사항'),
      body: DoitdoPaddingLayout(
        top: 16,
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorView(
            onRetry: () => ref.invalidate(noticeListProvider),
            colors: colors,
          ),
          data: (notices) {
            if (notices.isEmpty) {
              return Center(
                child: Text(
                  '공지사항이 없어요',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: colors.textHint,
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: notices.length,
              separatorBuilder: (_, __) => SizedBox(height: 8.h),
              itemBuilder: (_, i) => _NoticeRow(
                notice: notices[i],
                onTap: () => showNoticeDetailSheet(
                  context,
                  noticeId: notices[i].noticeId,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NoticeRow extends StatelessWidget {
  const _NoticeRow({required this.notice, required this.onTap});

  final NoticeResp notice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notice.title,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (notice.createdAt != null) ...[
                      SizedBox(height: 4.h),
                      Text(
                        _formatDate(notice.createdAt!),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: colors.textHint,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.textHint,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return iso;
    final y = parsed.year;
    final m = parsed.month.toString().padLeft(2, '0');
    final d = parsed.day.toString().padLeft(2, '0');
    return '$y.$m.$d';
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry, required this.colors});

  final VoidCallback onRetry;
  final DoitdoColors colors;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '공지사항을 불러오지 못했어요.',
            style: AppTextStyles.bodyMedium.copyWith(color: colors.textHint),
          ),
          SizedBox(height: 12.h),
          TextButton(
            onPressed: onRetry,
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}
