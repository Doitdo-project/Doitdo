import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:doitdo/core/theme/app_colors.dart';
import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/pages/shop/shop_state.dart';
import 'package:doitdo/presentation/pages/shop/shop_view_model.dart';
import 'package:doitdo/presentation/pages/shop/widgets/coin_icon.dart';
import 'package:doitdo/presentation/pages/shop/widgets/purchase_dialog.dart';
import 'package:doitdo/presentation/pages/shop/widgets/shop_category_tabs.dart';
import 'package:doitdo/presentation/pages/shop/widgets/shop_item_card.dart';
import 'package:doitdo/presentation/pages/shop/widgets/shop_room_preview.dart';
import 'package:doitdo/presentation/widgets/common/doitdo_top_bar.dart';
import 'package:doitdo/presentation/widgets/layouts/doitdo_scaffold.dart';

/// 다마고치 홈 → 상점 진입 페이지.
///
/// 상단: 코인 잔액 / 본문: 방 미리보기 → 카테고리 탭 → 상품 그리드.
/// 상품 카드의 "구매" 탭 시 [PurchaseDialog] 가 떠서 단일 액션으로 구매·배치를 처리한다.
class ShopPage extends ConsumerWidget {
  const ShopPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(shopViewModelProvider);

    return DoitdoScaffold(
      topBar: DoitdoTopBar(
        title: '상점',
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: Center(
              child: _CoinBadge(coins: asyncState.valueOrNull?.coins ?? 0),
            ),
          ),
        ],
      ),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorView(
          message: '상점을 불러오지 못했어요. 잠시 후 다시 시도해주세요.',
          onRetry: () => ref.invalidate(shopViewModelProvider),
        ),
        data: (state) => _ShopBody(state: state),
      ),
    );
  }
}

class _ShopBody extends ConsumerWidget {
  const _ShopBody({required this.state});

  final ShopState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(shopViewModelProvider.notifier);
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 16.h),
          child: state.displayItems.isEmpty
              ? const ShopRoomPreviewEmpty()
              : ShopRoomPreview(items: state.displayItems),
        ),
        ShopCategoryTabs(
          selected: state.selectedCategory,
          onSelect: vm.selectCategory,
        ),
        SizedBox(height: 16.h),
        Expanded(
          child: _ItemGrid(
            items: state.visibleItems,
            previewingItemId: state.previewingItemId,
            onTapPreview: (item) => vm.togglePreview(item.id),
            onTapBuy: (item) => _openPurchaseDialog(context, ref, item),
            onTapPlace: (item) => _runAction(
              context: context,
              run: () => vm.place(item.id),
              successMsg: '"${item.name}"을(를) 방에 배치했어요!',
              failureMsg: '배치에 실패했어요. 잠시 후 다시 시도해주세요.',
            ),
            onTapUnplace: (item) => _runAction(
              context: context,
              run: () => vm.unplace(item.id),
              successMsg: '"${item.name}"을(를) 방에서 뺐어요.',
              failureMsg: '해제에 실패했어요. 잠시 후 다시 시도해주세요.',
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openPurchaseDialog(
    BuildContext context,
    WidgetRef ref,
    ShopItem item,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final coins = ref.read(shopViewModelProvider).valueOrNull?.coins ?? 0;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => PurchaseDialog(item: item, currentCoins: coins),
    );
    if (confirmed != true) return;

    final ok =
        await ref.read(shopViewModelProvider.notifier).purchaseAndPlace(item.id);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? '"${item.name}"을(를) 방에 배치했어요!'
              : '구매에 실패했어요. 코인 잔액이나 네트워크를 확인해주세요.',
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// place / unplace 공통 호출 래퍼. ViewModel 이 false 를 돌려주면 실패 스낵바.
  Future<void> _runAction({
    required BuildContext context,
    required Future<bool> Function() run,
    required String successMsg,
    required String failureMsg,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await run();
    if (!context.mounted) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(ok ? successMsg : failureMsg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(color: colors.textSecondary),
            ),
            SizedBox(height: 16.h),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemGrid extends StatelessWidget {
  const _ItemGrid({
    required this.items,
    required this.previewingItemId,
    required this.onTapPreview,
    required this.onTapBuy,
    required this.onTapPlace,
    required this.onTapUnplace,
  });

  final List<ShopItem> items;
  final String? previewingItemId;
  final ValueChanged<ShopItem> onTapPreview;
  final ValueChanged<ShopItem> onTapBuy;
  final ValueChanged<ShopItem> onTapPlace;
  final ValueChanged<ShopItem> onTapUnplace;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      final colors = context.colors;
      return Center(
        child: Text(
          '아직 등록된 상품이 없어요',
          style: AppTextStyles.bodySmall.copyWith(color: colors.textHint),
        ),
      );
    }
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14.h,
        crossAxisSpacing: 12.w,
        // 카드 가로:세로 비. 너비는 grid 가 (스크린 - padding) 으로 고정해주고
        // 이 값만 카드 높이를 결정. 올리면 카드 짧아지고 핑크 미리보기 영역도
        // 같이 줄어든다 (Expanded 가 남는 공간 먹는 구조라).
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return ShopItemCard(
          item: item,
          isPreviewing: item.id == previewingItemId,
          onTapPreview: () => onTapPreview(item),
          onTapBuy: () => onTapBuy(item),
          onTapPlace: () => onTapPlace(item),
          onTapUnplace: () => onTapUnplace(item),
        );
      },
    );
  }
}

class _CoinBadge extends StatelessWidget {
  const _CoinBadge({required this.coins});

  final int coins;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: AppColors.streakBg,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.streakCheck.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CoinIcon(size: 18.sp),
          SizedBox(width: 4.w),
          Text(
            _formatCoins(coins),
            style: AppTextStyles.labelMedium.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatCoins(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}
