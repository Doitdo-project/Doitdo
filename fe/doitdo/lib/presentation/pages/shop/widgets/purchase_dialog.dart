import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/pages/shop/shop_state.dart';
import 'package:doitdo/presentation/pages/shop/widgets/coin_icon.dart';
import 'package:doitdo/presentation/pages/shop/widgets/shop_room_preview.dart'
    show shopCategoryAccent;

/// 상품 카드 → "구매" 버튼 탭 시 띄우는 주문서 확인 모달.
///
/// 구조: 헤더 / 미리보기 / 카테고리 칩 / 상품명 / 가격 카드 / CTA.
/// 가격 카드는 가격(큰)과 "구매 후 잔액"(부캡션)을 한 박스에 묶어서
/// 코인 아이콘이 화면에 흩어지지 않도록 한다. 부족 케이스에선 부캡션이
/// "X코인이 부족해요" 빨간 톤으로 바뀌고 CTA 가 비활성화된다.
///
/// Returns: `Navigator.pop(true)` = 구매 확정 / `pop(false)` = 닫기.
class PurchaseDialog extends StatelessWidget {
  const PurchaseDialog({
    super.key,
    required this.item,
    required this.currentCoins,
  });

  final ShopItem item;
  final int currentCoins;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final canAfford = currentCoins >= item.price;
    final shortage = canAfford ? 0 : item.price - currentCoins;
    // canAfford 가 false 일 때 음수가 되지 않도록 0 으로 클램프.
    final remainingAfter = canAfford ? currentCoins - item.price : 0;

    return Dialog(
      backgroundColor: colors.surface,
      insetPadding: EdgeInsets.symmetric(horizontal: 32.w),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      child: ConstrainedBox(
        // 작은 디바이스에서 콘텐츠가 화면을 넘치지 않도록 최대 높이 제한 + 스크롤.
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(onClose: () => Navigator.of(context).pop(false)),
              SizedBox(height: 12.h),
              _Preview(item: item),
              SizedBox(height: 18.h),
              Center(child: _CategoryChip(category: item.category)),
              SizedBox(height: 8.h),
              Text(
                item.name,
                textAlign: TextAlign.center,
                style: AppTextStyles.titleLarge.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              SizedBox(height: 16.h),
              _PriceCard(
                price: item.price,
                remainingAfter: remainingAfter,
                shortage: shortage,
                canAfford: canAfford,
              ),
              SizedBox(height: 20.h),
              _ConfirmButton(
                canAfford: canAfford,
                onConfirm: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // Stack 으로 타이틀을 진짜 가운데 정렬. 닫기 버튼 폭에 의존하던 더미
    // SizedBox 방식은 IconButton 실측 폭과 어긋나 살짝 비대칭이었다.
    return SizedBox(
      height: 40.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            '주문서 확인',
            style: AppTextStyles.titleLarge.copyWith(color: colors.textPrimary),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 36.w,
              height: 36.w,
              child: IconButton(
                icon: Icon(Icons.close_rounded, size: 22.sp),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                onPressed: onClose,
                color: colors.textSecondary,
                tooltip: '닫기',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.item});

  final ShopItem item;

  @override
  Widget build(BuildContext context) {
    final accent = shopCategoryAccent(item.category);
    final fallback = Icon(item.category.icon, size: 64.sp, color: accent);
    return Container(
      height: 150.h,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      alignment: Alignment.center,
      padding: EdgeInsets.all(16.w),
      child: item.imageUrl.isEmpty
          ? fallback
          : Image.network(
              item.imageUrl,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              errorBuilder: (_, _, _) => fallback,
            ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category});

  final ShopCategory category;

  @override
  Widget build(BuildContext context) {
    final accent = shopCategoryAccent(category);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(category.icon, size: 12.sp, color: accent),
          SizedBox(width: 4.w),
          Text(
            category.label,
            style: AppTextStyles.labelSmall.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// 가격(큰 글씨) + "구매 후 잔액" 부캡션을 한 박스에 묶은 카드.
/// 부족 케이스에선 부캡션이 빨간 톤의 부족 안내로 바뀐다.
class _PriceCard extends StatelessWidget {
  const _PriceCard({
    required this.price,
    required this.remainingAfter,
    required this.shortage,
    required this.canAfford,
  });

  final int price;
  final int remainingAfter;
  final int shortage;
  final bool canAfford;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: colors.streakCardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CoinIcon(size: 22.sp),
              SizedBox(width: 6.w),
              Text(
                _formatCoins(price),
                style: AppTextStyles.titleLarge.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          canAfford
              ? _RemainingCaption(remainingAfter: remainingAfter)
              : _ShortageCaption(shortage: shortage),
        ],
      ),
    );
  }
}

class _RemainingCaption extends StatelessWidget {
  const _RemainingCaption({required this.remainingAfter});

  final int remainingAfter;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '구매 후 잔액 ',
          style: AppTextStyles.bodySmall.copyWith(color: colors.textSecondary),
        ),
        CoinIcon(size: 14.sp),
        SizedBox(width: 2.w),
        Text(
          _formatCoins(remainingAfter),
          style: AppTextStyles.bodySmall.copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ShortageCaption extends StatelessWidget {
  const _ShortageCaption({required this.shortage});

  final int shortage;

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    return Text(
      '${_formatCoins(shortage)}코인이 부족해요',
      style: AppTextStyles.bodySmall.copyWith(
        color: error,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({required this.canAfford, required this.onConfirm});

  final bool canAfford;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: double.infinity,
      height: 50.h,
      child: ElevatedButton(
        onPressed: canAfford ? onConfirm : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.streakDotActive,
          foregroundColor: Colors.white,
          disabledBackgroundColor: colors.surfaceAlt,
          disabledForegroundColor: colors.textHint,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
          textStyle: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        child: Text(canAfford ? '구매하고 바로 배치하기' : '코인이 부족해요'),
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
