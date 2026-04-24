import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:doitdo/core/theme/app_colors.dart';
import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/models/collection_entry.dart';

/// 도감에서 해금된 캐릭터를 탭했을 때 보여주는 상세 바텀시트.
class CharacterDetailSheet extends StatelessWidget {
  const CharacterDetailSheet({super.key, required this.entry});

  final CollectionEntry entry;

  // 주황 accent — NOW 뱃지 / 현재 단계 테두리 강조.
  static const Color _accent = AppColors.streakCheck;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: EdgeInsets.fromLTRB(8.w, 8.h, 8.w, 16.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 16.h),
          Center(child: _HeroThumbnail(thumbnailUrl: entry.thumbnailUrl)),
          SizedBox(height: 12.h),
          Center(
            child: Text(
              '#${entry.characterId.toString().padLeft(3, '0')}',
              style: AppTextStyles.labelMedium.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
          SizedBox(height: 4.h),
          Center(
            child: Text(
              entry.species,
              style: AppTextStyles.titleLarge.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ),
          SizedBox(height: 24.h),
          _BirthStorySection(story: entry.birthStory),
          SizedBox(height: 24.h),
          Text(
            '진화 트리',
            style:
                AppTextStyles.bodyMedium.copyWith(color: colors.textPrimary),
          ),
          SizedBox(height: 12.h),
          _EvolutionTree(steps: entry.evolutionTree),
        ],
      ),
    );
  }
}

class _BirthStorySection extends StatelessWidget {
  const _BirthStorySection({required this.story});

  final String story;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '탄생 배경',
          style: AppTextStyles.bodyMedium.copyWith(color: colors.textPrimary),
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: AppColors.streakBg,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Text(
            story.isEmpty ? '아직 기록되지 않은 이야기예요.' : story,
            style: AppTextStyles.labelMedium.copyWith(
              color: colors.textPrimary,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroThumbnail extends StatelessWidget {
  const _HeroThumbnail({required this.thumbnailUrl});

  final String thumbnailUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140.w,
      height: 140.w,
      decoration: BoxDecoration(
        color: AppColors.streakBg,
        borderRadius: BorderRadius.circular(16.r),
      ),
      padding: EdgeInsets.all(24.w),
      child: thumbnailUrl.isEmpty
          ? _HeroFallback()
          : Image.network(
              thumbnailUrl,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              errorBuilder: (_, _, _) => _HeroFallback(),
            ),
    );
  }
}

class _HeroFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Icon(Icons.pets, size: 72.sp, color: context.colors.textHint);
  }
}

/// 진화 트리.
///
/// 이미지 카드 행과 라벨(이름/LV) 행을 **분리된 2단 Row** 로 그린다.
/// 이미지 카드는 정사각이고 Row 의 `center` 정렬이 카드 중앙에 맞춰지므로
/// 화살표가 자연스럽게 **이미지 중앙** 과 수평 정렬된다.
/// 라벨 행에는 화살표와 동일 폭의 투명 spacer 를 넣어 칸 폭을 맞춘다.
class _EvolutionTree extends StatelessWidget {
  const _EvolutionTree({required this.steps});

  final List<EvolutionStep> steps;

  static const double _arrowSize = 20;
  static const double _cellInnerPadding = 6;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (var i = 0; i < steps.length; i++) ...[
              Expanded(
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: _cellInnerPadding.w),
                  child: _EvolutionCardBody(step: steps[i]),
                ),
              ),
              if (i != steps.length - 1)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2.w),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: _arrowSize.sp,
                    color: colors.textSecondary,
                  ),
                ),
            ],
          ],
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            for (var i = 0; i < steps.length; i++) ...[
              Expanded(
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: _cellInnerPadding.w),
                  child: _EvolutionCardLabel(step: steps[i]),
                ),
              ),
              // 화살표 폭만큼 비워 라벨과 이미지의 칸 폭을 맞춘다.
              if (i != steps.length - 1)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2.w),
                  child: SizedBox(width: _arrowSize.sp),
                ),
            ],
          ],
        ),
      ],
    );
  }
}

class _EvolutionCardBody extends StatelessWidget {
  const _EvolutionCardBody({required this.step});

  final EvolutionStep step;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = CharacterDetailSheet._accent;
    final isCurrent = step.isCurrent;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.streakBg,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: isCurrent ? accent : colors.border,
                width: isCurrent ? 2 : 1,
              ),
            ),
            padding: EdgeInsets.all(8.w),
            child: Center(
              child: step.isUnlocked && step.thumbnailUrl.isNotEmpty
                  ? Image.network(
                      step.thumbnailUrl,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (_, _, _) => Text(
                        '?',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    )
                  : Text(
                      '?',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
            ),
          ),
        ),
        if (isCurrent)
          Positioned(
            top: -8.h,
            right: -4.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                '현재',
                style: AppTextStyles.labelSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _EvolutionCardLabel extends StatelessWidget {
  const _EvolutionCardLabel({required this.step});

  final EvolutionStep step;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          step.name,
          style: AppTextStyles.labelMedium.copyWith(
            color: step.isUnlocked ? colors.textPrimary : colors.textSecondary,
          ),
        ),
        Text(
          'LV.${step.level}',
          style: AppTextStyles.labelSmall.copyWith(
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}
