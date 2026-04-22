import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:doitdo/core/theme/app_colors.dart';
import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';

/// 도감 상단의 "전체 N종 중 M종 발견" 진행도 카드.
///
/// 크림 배경 + 세그먼트 진행도 바. 세그먼트는 `totalCount` 만큼 칸이 나뉘어,
/// 해금된 종 수만큼 주황으로 채워진다. "몇 종 중 몇 종" 을 수치와 그림으로
/// 동시에 보여주는 효과.
class CollectionProgressCard extends StatelessWidget {
  const CollectionProgressCard({
    super.key,
    required this.totalCount,
    required this.unlockedCount,
    required this.progress,
  });

  final int totalCount;
  final int unlockedCount;

  /// 0.0 ~ 1.0. 세그먼트 바에서는 직접 쓰이진 않지만 외부 호출 시그니처 유지를
  /// 위해 남겨둔다(예: 접근성 value 로 사용 가능).
  final double progress;

  static const Color _trackColor = Color(0xFFEAE8DE);
  static const Color _fillColor = AppColors.streakCheck; // 주황 accent

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: AppColors.streakBg,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                '전체 ',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              Text(
                '$totalCount종',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                ' 중 ',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              Text(
                '$unlockedCount종',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: _fillColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                ' 발견',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          _SegmentedProgressBar(
            totalCount: totalCount,
            filledCount: unlockedCount,
            trackColor: _trackColor,
            fillColor: _fillColor,
          ),
        ],
      ),
    );
  }
}

/// 세그먼트 진행도 바.
///
/// [totalCount] 만큼 칸을 같은 폭으로 나눠 놓고, 앞에서부터 [filledCount] 칸을
/// 채운다. 바깥은 라운드 트랙, 각 칸도 살짝 라운드 지도록 처리해 부드러운 톤.
class _SegmentedProgressBar extends StatelessWidget {
  const _SegmentedProgressBar({
    required this.totalCount,
    required this.filledCount,
    required this.trackColor,
    required this.fillColor,
  });

  final int totalCount;
  final int filledCount;
  final Color trackColor;
  final Color fillColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 14.h,
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(6.r),
      ),
      padding: EdgeInsets.all(2.w),
      child: Row(
        children: [
          for (var i = 0; i < totalCount; i++) ...[
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: i < filledCount ? fillColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(3.r),
                ),
              ),
            ),
            if (i != totalCount - 1) SizedBox(width: 2.w),
          ],
        ],
      ),
    );
  }
}
