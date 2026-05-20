import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';

/// 인증 폼 안에 들어가는 정보 안내 카드.
///
/// 사용자의 흐름을 다른 방향으로 유도해야 할 때 (예: 회원가입 권유, 소셜 계정 안내)
/// 다이얼로그 대신 폼 안에 인라인으로 끼워 넣는다. 입력 컨텍스트(이메일 필드 등) 가
/// 그대로 노출돼 오타 수정 같은 정정 흐름이 자연스럽다.
///
/// 시각 톤:
/// - 라운드 14, 따뜻한 베이지 배경 + 옅은 외곽선 — 에러가 아니라 "정보 안내" 임을 강조
/// - 좌측 정보 아이콘 + 굵은 타이틀
/// - 본문은 한 톤 약하게(textSecondary)
/// - 하단에 1개 CTA 버튼 (가득찬 폭). 보조 액션이 필요한 경우 [onDismiss] 로 닫기.
class AuthInlineNotice extends StatelessWidget {
  const AuthInlineNotice({
    super.key,
    required this.title,
    required this.message,
    required this.ctaLabel,
    required this.onCta,
    this.icon = Icons.info_outline_rounded,
    this.onDismiss,
  });

  final String title;
  final String message;
  final String ctaLabel;
  final VoidCallback onCta;
  final IconData icon;

  /// 우측 상단 X 닫기. null 이면 X 아이콘 자체를 렌더링하지 않는다.
  /// (이메일 재입력으로 자동 dismiss 되는 경우엔 굳이 X 안 둠.)
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 14.w, 16.h),
      decoration: BoxDecoration(
        // 페이지 배경(#F8F5EC) 보다 살짝 밝은 톤 — 평행 카드처럼 떠 보이게.
        color: const Color(0xFFFDF8EE),
        border: Border.all(color: const Color(0xFFE8DFCB)),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18.sp, color: const Color(0xFFC97A3F)),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: colors.textPrimary,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (onDismiss != null)
                GestureDetector(
                  onTap: onDismiss,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: EdgeInsets.only(left: 8.w),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18.sp,
                      color: colors.textHint,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 8.h),
          // 아이콘 폭만큼 들여써서 타이틀과 본문의 좌측 정렬을 맞춤.
          Padding(
            padding: EdgeInsets.only(left: 26.w),
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: colors.textSecondary,
                fontSize: 13.sp,
                height: 1.4,
              ),
            ),
          ),
          SizedBox(height: 14.h),
          // 카드 내부 CTA — 메인 앱 디자인 시스템과 통일된 radius 12.
          // 컬러는 페이지 메인 primary 버튼과 시각적 위계가 구분되도록 톤다운된
          // 베이지/브라운 secondary 톤 유지.
          SizedBox(
            height: 44.h,
            child: ElevatedButton(
              onPressed: onCta,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE5D9C0),
                foregroundColor: const Color(0xFF3A352D),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                textStyle: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(ctaLabel),
                  SizedBox(width: 4.w),
                  Icon(Icons.chevron_right_rounded, size: 18.sp),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
