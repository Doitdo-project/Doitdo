import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/domain/entities/furniture_theme.dart';
import 'package:doitdo/presentation/pages/shop/shop_state.dart';
import 'package:doitdo/presentation/pages/shop/shop_view_model.dart';
import 'package:doitdo/presentation/pages/shop/widgets/coin_icon.dart';
import 'package:doitdo/presentation/pages/shop/widgets/purchase_dialog.dart';
import 'package:doitdo/presentation/pages/shop/widgets/shop_category_tabs.dart';
import 'package:doitdo/presentation/pages/shop/widgets/shop_item_card.dart';
import 'package:doitdo/presentation/pages/shop/widgets/shop_loading_view.dart';
import 'package:doitdo/presentation/pages/shop/widgets/shop_room_preview.dart';
import 'package:doitdo/presentation/pages/shop/widgets/shop_theme_card.dart';
import 'package:doitdo/presentation/pages/shop/widgets/shop_top_tabs.dart';
import 'package:doitdo/presentation/pages/shop/widgets/theme_purchase_dialog.dart';
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

    // 초기 로딩 중에는 coins 가 아직 없어 0 으로 깜빡 보이는 게 어색 →
    // 잔액 뱃지 자체를 숨기고 데이터가 들어오면 그때 노출한다 (refresh 동안엔
    // valueOrNull 이 직전 값을 유지하므로 사라지지 않는다).
    final coins = asyncState.valueOrNull?.coins;
    return DoitdoScaffold(
      topBar: DoitdoTopBar(
        title: '상점',
        actions: [
          if (coins != null)
            Padding(
              padding: EdgeInsets.only(right: 16.w),
              child: Center(child: _CoinBadge(coins: coins)),
            ),
        ],
      ),
      body: asyncState.when(
        loading: () => const ShopLoadingView(),
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
        ShopTopTabs(
          selected: state.selectedTab,
          onSelect: vm.selectTab,
        ),
        if (state.selectedTab == ShopTab.furniture) ...[
          SizedBox(height: 12.h),
          ShopCategoryTabs(
            selected: state.selectedCategory,
            onSelect: vm.selectCategory,
          ),
          SizedBox(height: 16.h),
          Expanded(
            child: _ItemGrid(
              items: state.visibleItems,
              isPreviewing: state.isPreviewing,
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
        ] else ...[
          SizedBox(height: 16.h),
          Expanded(
            child: _ThemeGrid(
              themes: state.themes,
              previewingThemeCode: state.previewingThemeCode,
              onTapTheme: (theme) => _toggleThemePreview(context, ref, theme),
              onTapPurchase: (theme) =>
                  _openThemePurchaseDialog(context, ref, theme),
              onTapPlace: (theme) => _placeOwnedTheme(context, ref, theme),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _toggleThemePreview(
    BuildContext context,
    WidgetRef ref,
    FurnitureTheme theme,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final vm = ref.read(shopViewModelProvider.notifier);
    await vm.toggleThemePreview(
      theme.themeCode,
      onFailure: (message) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }

  /// 테마 카드의 "구매" 탭 → 주문서 다이얼로그 → 사용자 선택에 따라 분기 호출.
  ///
  /// - [ThemePurchaseChoice.purchaseAndPlace] → `purchaseAndPlaceTheme` (구매 + 배치)
  /// - [ThemePurchaseChoice.purchaseOnly] → `purchaseTheme` (구매만, 인벤토리로)
  ///
  /// 다이얼로그가 닫히는 즉시 success 스낵바 + 백그라운드 호출 (가구 구매와 동일
  /// 패턴). 실패 시 onFailure 콜백에서 에러 스낵바로 덮어쓴다.
  Future<void> _openThemePurchaseDialog(
    BuildContext context,
    WidgetRef ref,
    FurnitureTheme theme,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final shopState = ref.read(shopViewModelProvider).valueOrNull;
    final coins = shopState?.coins ?? 0;

    final choice = await showDialog<ThemePurchaseChoice>(
      context: context,
      barrierDismissible: true,
      builder: (_) => ThemePurchaseDialog(
        theme: theme,
        currentCoins: coins,
      ),
    );
    if (choice == null || choice == ThemePurchaseChoice.cancel) return;

    final successMsg = switch (choice) {
      ThemePurchaseChoice.purchaseAndPlace =>
        '"${theme.themeName}" 테마를 구매하고 배치했어요!',
      ThemePurchaseChoice.purchaseOnly =>
        '"${theme.themeName}" 테마를 인벤토리에 담았어요.',
      ThemePurchaseChoice.cancel => '',
    };
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(successMsg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );

    void showFailure(String message) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    final vm = ref.read(shopViewModelProvider.notifier);
    // unawaited — 백그라운드 실행, 결과 대기 안 함. 실패 시 onFailure 콜백.
    switch (choice) {
      case ThemePurchaseChoice.purchaseAndPlace:
        unawaited(
          vm.purchaseAndPlaceTheme(theme.themeCode, onFailure: showFailure),
        );
      case ThemePurchaseChoice.purchaseOnly:
        unawaited(
          vm.purchaseTheme(theme.themeCode, onFailure: showFailure),
        );
      case ThemePurchaseChoice.cancel:
        return;
    }
  }

  /// 풀세트 보유 테마 카드의 "배치" 탭 → 다이얼로그 없이 즉시 일괄 배치 (가구
  /// 카드의 "배치" 와 동일 톤). 같은 카테고리 기존 배치는 BE 가 자동 교체.
  Future<void> _placeOwnedTheme(
    BuildContext context,
    WidgetRef ref,
    FurnitureTheme theme,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final vm = ref.read(shopViewModelProvider.notifier);
    final ok = await vm.placeOwnedTheme(
      theme.themeCode,
      onFailure: (message) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
    if (!ok || !context.mounted) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('"${theme.themeName}" 테마를 방에 배치했어요!'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openPurchaseDialog(
      BuildContext context,
      WidgetRef ref,
      ShopItem item,
      ) async {
    final messenger = ScaffoldMessenger.of(context);
    final shopState = ref.read(shopViewModelProvider).valueOrNull;
    final coins = shopState?.coins ?? 0;
    // 같은 카테고리에 이미 배치된 다른 아이템이 있을 때만 "구매만 하기" 옵션을
    // dialog 에 추가로 보여준다 — 평소 단일 액션 모달의 흐름은 그대로 유지하고,
    // 정작 교체가 일어나는 케이스에서만 사용자가 결정권을 갖게 한다.
    final hasPlacedInCategory = shopState != null &&
        shopState.items.any(
          (it) => it.category == item.category && it.status == ItemStatus.placed,
        );

    final choice = await showDialog<PurchaseChoice>(
      context: context,
      barrierDismissible: true,
      builder: (_) => PurchaseDialog(
        item: item,
        currentCoins: coins,
        hasPlacedInSameCategory: hasPlacedInCategory,
      ),
    );
    if (choice == null || choice == PurchaseChoice.cancel) return;

    // 다이얼로그 닫히는 즉시 success 스낵바 + 낙관 업데이트.
    // 서버 호출은 background, 실패 시 onFailure 콜백에서 에러 스낵바로 덮어씀.
    final successMsg = switch (choice) {
      PurchaseChoice.purchaseAndPlace => '"${item.name}"을(를) 방에 배치했어요!',
      PurchaseChoice.purchaseOnly => '"${item.name}"을(를) 인벤토리에 담았어요.',
      PurchaseChoice.cancel => '',
    };
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(successMsg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );

    void showFailure(String message) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    final vm = ref.read(shopViewModelProvider.notifier);
    // unawaited — 백그라운드 실행, 결과 대기 안 함. 실패 시 onFailure 콜백.
    switch (choice) {
      case PurchaseChoice.purchaseAndPlace:
        vm.purchaseAndPlace(item.id, onFailure: showFailure);
      case PurchaseChoice.purchaseOnly:
        vm.purchaseOnly(item.id, onFailure: showFailure);
      case PurchaseChoice.cancel:
        return;
    }
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
    required this.isPreviewing,
    required this.onTapPreview,
    required this.onTapBuy,
    required this.onTapPlace,
    required this.onTapUnplace,
  });

  final List<ShopItem> items;

  /// 카드별로 미리보기 토글 상태를 묻는 술어. 멀티 미리보기 도입으로 단일 id
  /// 비교가 아닌 카테고리당 1개 매핑을 보는 [ShopState.isPreviewing] 을 그대로
  /// 받는다.
  final bool Function(String itemId) isPreviewing;
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
          isPreviewing: isPreviewing(item.id),
          onTapPreview: () => onTapPreview(item),
          onTapBuy: () => onTapBuy(item),
          onTapPlace: () => onTapPlace(item),
          onTapUnplace: () => onTapUnplace(item),
        );
      },
    );
  }
}

class _ThemeGrid extends StatelessWidget {
  const _ThemeGrid({
    required this.themes,
    required this.previewingThemeCode,
    required this.onTapTheme,
    required this.onTapPurchase,
    required this.onTapPlace,
  });

  final List<FurnitureTheme> themes;
  final String? previewingThemeCode;
  final ValueChanged<FurnitureTheme> onTapTheme;
  final ValueChanged<FurnitureTheme> onTapPurchase;
  final ValueChanged<FurnitureTheme> onTapPlace;

  @override
  Widget build(BuildContext context) {
    if (themes.isEmpty) {
      final colors = context.colors;
      return Center(
        child: Text(
          '아직 등록된 테마가 없어요',
          style: AppTextStyles.bodySmall.copyWith(color: colors.textHint),
        ),
      );
    }
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h),
      itemCount: themes.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14.h,
        crossAxisSpacing: 12.w,
        // 카드 가로:세로 비. 가구 카드(0.85) 보다 살짝 길게 — 가격 행 + 버튼이
        // 추가돼 같은 0.85 면 썸네일이 너무 작아진다.
        childAspectRatio: 0.72,
      ),
      itemBuilder: (context, index) {
        final theme = themes[index];
        return ShopThemeCard(
          theme: theme,
          isPreviewing: theme.themeCode == previewingThemeCode,
          onTap: () => onTapTheme(theme),
          onTapPurchase: () => onTapPurchase(theme),
          onTapPlace: () => onTapPlace(theme),
        );
      },
    );
  }
}

/// 상점 상단 코인 잔액 뱃지. 탭하면 [StatusPill] 의 스트릭/단계 팝오버와 동일한
/// 톤(흰 카드 + 꼬리) 으로 "코인을 어떻게 모으는지" 안내를 띄운다 — 신규 사용자가
/// 코인 획득 경로를 따로 찾지 않아도 되도록 한 화면 안에서 자기 설명적이게.
class _CoinBadge extends StatefulWidget {
  const _CoinBadge({required this.coins});

  final int coins;

  @override
  State<_CoinBadge> createState() => _CoinBadgeState();
}

class _CoinBadgeState extends State<_CoinBadge> {
  final GlobalKey _anchorKey = GlobalKey();
  OverlayEntry? _entry;

  @override
  void dispose() {
    _hidePopover();
    super.dispose();
  }

  void _hidePopover() {
    _entry?.remove();
    _entry = null;
  }

  void _showPopover() {
    if (!mounted) return;
    _hidePopover();

    final box = _anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final overlayState = Overlay.of(context, rootOverlay: true);
    final overlayBox = overlayState.context.findRenderObject() as RenderBox;
    final pos = box.localToGlobal(Offset.zero, ancestor: overlayBox);
    final anchorSize = box.size;
    final screen = overlayBox.size;
    final horizontalPadding = 16.w;
    final cardWidth = 260.w;
    final anchorCenterX = pos.dx + anchorSize.width / 2;
    final left = (anchorCenterX - cardWidth / 2).clamp(
      horizontalPadding,
      screen.width - horizontalPadding - cardWidth,
    );
    // 꼬리 좌표는 카드 좌측 기준. 카드가 화면 가장자리로 밀려도 꼬리는 anchor 중앙을
    // 가리키도록 위치 보정.
    final tailRelX = (anchorCenterX - left).clamp(20.w, cardWidth - 20.w);

    _entry = OverlayEntry(
      builder: (ctx) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _hidePopover,
              ),
            ),
            Positioned(
              left: left,
              width: cardWidth,
              // 코인 뱃지가 top bar 에 있으므로 팝오버는 아래로 열림 — 꼬리는 위쪽.
              top: pos.dy + anchorSize.height + 8.h,
              child: _CoinPopoverCard(
                tailLeft: tailRelX,
                child: const _CoinInfoContent(),
              ),
            ),
          ],
        );
      },
    );
    overlayState.insert(_entry!);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      key: _anchorKey,
      onTap: _showPopover,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: colors.streakCardBg,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: colors.streakDotActive.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CoinIcon(size: 18.sp),
            SizedBox(width: 4.w),
            Text(
              _formatCoins(widget.coins),
              style: AppTextStyles.labelMedium.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 상점 코인 뱃지 아래에 뜨는 팝오버 카드. [StatusPill] 의 흰 카드와 같은 톤이지만
/// 꼬리가 카드 상단에서 위쪽(anchor)을 가리킨다.
class _CoinPopoverCard extends StatelessWidget {
  const _CoinPopoverCard({required this.tailLeft, required this.child});

  /// 카드 좌측 기준 꼬리 중심 X (px, 이미 .w 스케일 적용된 값).
  final double tailLeft;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: child,
          ),
          Positioned(
            left: tailLeft - 8.w,
            top: -7.h,
            child: CustomPaint(
              size: Size(16.w, 8.h),
              painter: const _UpTailPainter(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpTailPainter extends CustomPainter {
  const _UpTailPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width / 2, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _UpTailPainter old) => old.color != color;
}

class _CoinInfoContent extends StatelessWidget {
  const _CoinInfoContent();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '코인은 이렇게 모을 수 있어요',
            style: AppTextStyles.bodySmall.copyWith(color: Colors.black),
          ),
          SizedBox(height: 10.h),
          Container(height: 1, color: const Color(0xFFF0F0F0)),
          SizedBox(height: 10.h),
          Text(
            '✅ 할 일을 완료할 때마다 코인을 모을 수 있어요\n🔥 7일 연속 달성 시 보너스 코인도 받을 수 있어요!',
            style: AppTextStyles.labelSmall.copyWith(
              color: Colors.black54,
              height: 1.5,
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