import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_primary_button.dart';

/// ADULT + canFarewell 상태에서만 홈에 노출되는 "독립 시키기" 배너.
///
/// 캐릭터 카드 아래에 작게 붙는 CTA. 탭 → 확인 다이얼로그 → farewell API.
/// 실행 중에는 버튼이 비활성화되고 스피너가 보인다.
class FarewellBanner extends StatelessWidget {
  const FarewellBanner({
    super.key,
    required this.characterName,
    required this.onTap,
    this.busy = false,
  });

  final String characterName;
  final VoidCallback onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final displayName = characterName.isEmpty ? '다마고치' : characterName;

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$displayName가 독립할 준비가 됐어요',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '배웅해주면 다음 알이 도착해요.',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          DoitdoPrimaryButton(
            label: busy ? '처리 중…' : '독립 시키기',
            onPressed: busy ? null : onTap,
            expand: false,
            height: 36,
          ),
        ],
      ),
    );
  }
}
