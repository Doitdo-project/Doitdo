import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:doitdo/core/theme/app_colors.dart';
import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/models/collection_entry.dart';

/// 도감 그리드 한 칸.
///
/// 도감 화면 전체를 **따뜻한 픽셀 톤** 으로 맞추기 위해:
/// - 외곽: 1px solid `AppColors.subHeader` (갈색)
/// - 모서리: `4.r` (거의 각진)
/// - 배경: `AppColors.streakBg` (크림)
///
/// 2회 이상 만난 캐릭터는 우상단에 `xN` 뱃지 노출.
/// [onTap] 은 미해금 포함해 항상 호출되며, 해금 여부 분기는 부모에서 처리.
class CollectionGridEntry extends StatelessWidget {
  const CollectionGridEntry({
    super.key,
    required this.entry,
    this.onTap,
  });

  final CollectionEntry entry;
  final VoidCallback? onTap;

  // 카드 내부 padding — 값을 키우면 이미지가 더 작아진다.
  static const double _cardInnerPadding = 18;
  static const double _cardRadius = 12;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final unlocked = entry.isUnlocked;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(_cardRadius.r),
              child: AspectRatio(
                aspectRatio: 0.85,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.streakBg,
                        borderRadius: BorderRadius.circular(_cardRadius.r),
                        border: Border.all(color: colors.border, width: 1),
                      ),
                      padding: EdgeInsets.all(_cardInnerPadding.w),
                      child: _Thumbnail(entry: entry),
                    ),
                    if (unlocked && entry.meetCount >= 2)
                      Positioned(
                        top: 6.h,
                        right: 6.w,
                        child: _MeetCountBadge(count: entry.meetCount),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          unlocked ? entry.species : '???',
          style: AppTextStyles.labelLarge.copyWith(
            color: unlocked ? colors.textPrimary : colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.entry});

  final CollectionEntry entry;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      entry.thumbnailUrl,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.none,
    );

    if (entry.isUnlocked) return Center(child: image);

    // 미해금: 같은 썸네일을 검정으로 덮어 실루엣 표현.
    // 썸네일 asset 이 종별로 확정되면 per-character silhouette 로 교체해도 된다.
    return Center(
      child: ColorFiltered(
        colorFilter: const ColorFilter.mode(
          Color(0xFF2B2B2B),
          BlendMode.srcATop,
        ),
        child: image,
      ),
    );
  }
}

class _MeetCountBadge extends StatelessWidget {
  const _MeetCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppColors.streakCheck, // 주황 accent
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        'x$count',
        style: AppTextStyles.labelSmall.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
