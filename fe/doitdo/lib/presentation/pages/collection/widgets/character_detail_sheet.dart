import 'package:doitdo/core/theme/app_colors.dart';
import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/models/collection_entry.dart';
import 'package:doitdo/presentation/providers/app_data_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 탭한 종에 대해 상세 API 를 호출해 바텀시트 내용에 바인딩하는 FutureProvider.
///
/// 바텀시트가 열릴 때 한 번 호출되고, 닫히면 autoDispose 로 해제된다.
final encyclopediaDetailProvider = FutureProvider.autoDispose
    .family<EncyclopediaDetail, String>((ref, species) async {
  final repo = ref.watch(characterRepositoryProvider);
  return repo.getEncyclopediaDetail(species);
});

/// 도감에서 해금된 캐릭터를 탭했을 때 보여주는 상세 바텀시트.
///
/// [species] 는 BE 의 종 enum 값(예: `CAT`). 열리는 순간 상세 API 를 호출해
/// birthBackground / encounterCount / 진화 3단계 정보를 받아 렌더한다.
/// [currentStage] 는 리스트에서 넘겨준 사용자의 현재 단계로, 진화 트리에서
/// "현재" 배지 위치를 결정한다.
class CharacterDetailSheet extends ConsumerWidget {
  const CharacterDetailSheet({
    super.key,
    required this.species,
    required this.currentStage,
  });

  final String species;
  final CharacterStage currentStage;

  // 주황 accent — 현재 단계 테두리/배지 강조.
  static const Color _accent = AppColors.streakCheck;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDetail = ref.watch(encyclopediaDetailProvider(species));
    return Padding(
      padding: EdgeInsets.fromLTRB(8.w, 8.h, 8.w, 16.h),
      child: asyncDetail.when(
        loading: () => _LoadingBox(),
        error: (err, _) => _ErrorBox(
          onRetry: () => ref.invalidate(encyclopediaDetailProvider(species)),
        ),
        data: (detail) =>
            _DetailContent(detail: detail, currentStage: currentStage),
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.detail, required this.currentStage});

  final EncyclopediaDetail detail;
  final CharacterStage currentStage;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // 현재 단계 데이터를 헤더에 사용 (adult 를 가리지 않도록 실제 진행에 맞춤).
    final current = switch (currentStage) {
      CharacterStage.baby => detail.baby,
      CharacterStage.teen => detail.teen,
      CharacterStage.adult => detail.adult,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 16.h),
        Center(child: _HeroThumbnail(thumbnailUrl: current.thumbnailUrl)),
        SizedBox(height: 12.h),
        Center(
          child: Text(
            current.name,
            style: AppTextStyles.titleLarge.copyWith(color: colors.textPrimary),
          ),
        ),
        if (detail.encounterCount > 0) ...[
          SizedBox(height: 6.h),
          Center(
            child: Text(
              '지금까지 ${detail.encounterCount}번 만났어요',
              style: AppTextStyles.labelSmall.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
        SizedBox(height: 24.h),
        _BirthStorySection(story: detail.birthBackground),
        SizedBox(height: 24.h),
        Text(
          '진화 트리',
          style: AppTextStyles.bodyMedium.copyWith(color: colors.textPrimary),
        ),
        SizedBox(height: 12.h),
        _EvolutionTree(detail: detail, currentStage: currentStage),
      ],
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
            // streakBg 가 라이트 전용 크림색이라 다크모드에서 colors.textPrimary
            // (흰색) 와 대비가 사라져 안 보임. 본문 글자는 항상 어두운 톤으로 고정.
            style: AppTextStyles.labelMedium.copyWith(
              color: Colors.black87,
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

/// 진화 트리. 이미지 카드 행과 라벨(이름 + 단계) 행을 분리된 Row 로 그린다.
/// 이미지 카드는 정사각이고 Row center 정렬이 카드 중앙에 맞춰지므로 화살표가
/// 자연스럽게 이미지 중앙과 수평 정렬된다.
class _EvolutionTree extends StatelessWidget {
  const _EvolutionTree({required this.detail, required this.currentStage});

  final EncyclopediaDetail detail;
  final CharacterStage currentStage;

  static const double _arrowSize = 20;
  static const double _cellInnerPadding = 6;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final stages = detail.stagesInOrder;

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (var i = 0; i < stages.length; i++) ...[
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: _cellInnerPadding.w,
                  ),
                  child: _EvolutionCardBody(data: stages[i].data),
                ),
              ),
              if (i != stages.length - 1)
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
            for (var i = 0; i < stages.length; i++) ...[
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: _cellInnerPadding.w,
                  ),
                  child: _EvolutionCardLabel(
                    name: stages[i].data.name,
                    stageLabel: stageLabelOf(stages[i].stage),
                  ),
                ),
              ),
              if (i != stages.length - 1)
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
  const _EvolutionCardBody({required this.data});

  final EncyclopediaStage data;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

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
                color: colors.border,
                width: 1,
              ),
            ),
            padding: EdgeInsets.all(8.w),
            child: Center(
              child: data.thumbnailUrl.isEmpty
                  ? Text(
                '?',
                style: AppTextStyles.titleMedium.copyWith(
                  color: colors.textSecondary,
                ),
              )
                  : Image.network(
                data.thumbnailUrl,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, _, _) => Text(
                  '?',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EvolutionCardLabel extends StatelessWidget {
  const _EvolutionCardLabel({required this.name, required this.stageLabel});

  final String name;
  final String stageLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          stageLabel,
          style: AppTextStyles.labelMedium.copyWith(color: colors.textPrimary),
        ),
      ],
    );
  }
}

class _LoadingBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240.h,
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      height: 240.h,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '상세 정보를 불러오지 못했어요.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: colors.textPrimary,
              ),
            ),
            SizedBox(height: 12.h),
            TextButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}
