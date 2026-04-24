import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:doitdo/core/theme/app_colors.dart';
import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/models/collection_entry.dart';
import 'package:doitdo/presentation/pages/collection/collection_state.dart';
import 'package:doitdo/presentation/pages/collection/collection_view_model.dart';
import 'package:doitdo/presentation/pages/collection/widgets/character_detail_sheet.dart';
import 'package:doitdo/presentation/pages/collection/widgets/collection_grid_entry.dart';
import 'package:doitdo/presentation/pages/collection/widgets/collection_progress_card.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_bottom_sheet.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_top_bar.dart';
import 'package:doitdo/presentation/widgets/layouts/doitdo_padding_layout.dart';
import 'package:doitdo/presentation/widgets/layouts/doitdo_scaffold.dart';

/// 다마고치 도감 페이지.
///
/// 상단 진행도 카드 + 3열 캐릭터 그리드 + 하단 안내 칩.
/// 해금된 캐릭터를 탭하면 상세 정보를 볼 수 있다(상세 다이얼로그는 후속 작업).
class CollectionPage extends ConsumerWidget {
  const CollectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(collectionViewModelProvider);

    return DoitdoScaffold(
      topBar: const DoitdoTopBar(title: '도감'),
      body: DoitdoPaddingLayout(
        top: 16,
        bottom: 16,
        child: asyncState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => _ErrorView(
            onRetry: () => ref.read(collectionViewModelProvider.notifier).load(),
          ),
          data: (state) => _CollectionBody(state: state),
        ),
      ),
    );
  }

}

/// 엔트리 탭 라우팅.
/// - 해금됨 → 상세 바텀시트.
/// - 미해금 → 안내 스낵바.
void _onEntryTap(BuildContext context, CollectionEntry entry) {
  if (entry.isUnlocked) {
    showDoitdoBottomSheet(
      context: context,
      child: CharacterDetailSheet(entry: entry),
    );
  } else {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('아직 만나지 못한 캐릭터예요.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
  }
}

class _CollectionBody extends StatelessWidget {
  const _CollectionBody({required this.state});

  final CollectionState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CollectionProgressCard(
          totalCount: state.totalCount,
          unlockedCount: state.unlockedCount,
          progress: state.progress,
        ),
        SizedBox(height: 20.h),
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.zero,
            itemCount: state.entries.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 16.h,
              crossAxisSpacing: 12.w,
              // 세로로 길쭉한 카드(aspect 0.85) + 라벨이 들어가도록 셀도 길게.
              childAspectRatio: 0.72,
            ),
            itemBuilder: (context, index) {
              final entry = state.entries[index];
              return CollectionGridEntry(
                entry: entry,
                onTap: () => _onEntryTap(context, entry),
              );
            },
          ),
        ),
        SizedBox(height: 8.h),
        const _FooterHint(
          text: '해금된 캐릭터를 터치하면 상세 정보를 볼 수 있습니다.',
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '도감을 불러오지 못했어요.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: colors.textPrimary,
            ),
          ),
          SizedBox(height: 12.h),
          TextButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}

class _FooterHint extends StatelessWidget {
  const _FooterHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.streakBg,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: colors.border, width: 1),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTextStyles.bodySmall.copyWith(color: colors.textSecondary),
      ),
    );
  }
}
