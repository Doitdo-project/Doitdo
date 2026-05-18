import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/domain/entities/furniture_theme.dart';
import 'package:doitdo/presentation/pages/shop/shop_state.dart';
import 'package:doitdo/presentation/pages/shop/widgets/coin_icon.dart';
import 'package:doitdo/presentation/pages/shop/widgets/shop_room_preview.dart'
    show shopCategoryAccent;

/// 주문서 확인 모달의 사용자 선택 결과 (가구 [PurchaseDialog] 의 PurchaseChoice
/// 와 같은 톤). 테마는 단일 가구가 아니어서 "같은 카테고리 교체 케이스에만
/// 보조 CTA" 같은 분기 없이 항상 두 버튼 모두 노출 — 어떤 테마든 "방에 즉시
/// 적용" / "인벤토리에만 추가" 를 사용자가 명시적으로 선택할 수 있게.
enum ThemePurchaseChoice {
  cancel,
  purchaseAndPlace,
  purchaseOnly,
}

/// 테마 카드의 "구매" 탭 시 띄우는 주문서 확인 모달.
///
/// 가구 [PurchaseDialog] 와 동일한 단일 컬럼 + 두 단 CTA 패턴:
/// - primary "구매하고 바로 배치하기" → [ThemePurchaseChoice.purchaseAndPlace]
/// - secondary "지금 배치하지 않고 구매만 하기" → [ThemePurchaseChoice.purchaseOnly]
///
/// 헤더 / 썸네일 / 보유 요약 / 구성 가구 리스트 / 가격 카드 / CTA 두 단의 단일
/// 컬럼. 잔액 부족이면 가격 카드 부캡션이 "X코인이 부족해요" 빨간 톤으로 바뀌고
/// CTA 두 개 모두 비활성화. 구성 가구가 많은 테마도 리스트가 내부에서 스크롤되어
/// 다이얼로그 외곽이 화면 밖으로 밀리지 않는다.
///
/// `alreadyOwned == true` 인 테마는 카드 버튼이 "배치" 라 이 다이얼로그가 열리지
/// 않는다 — 따라서 다이얼로그 자체는 "결제 발생" 케이스만 가정한다.
///
/// Returns: [ThemePurchaseChoice] (null = barrier 탭, cancel 동일 취급).
class ThemePurchaseDialog extends StatelessWidget {
  const ThemePurchaseDialog({
    super.key,
    required this.theme,
    required this.currentCoins,
  });

  final FurnitureTheme theme;
  final int currentCoins;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final canAfford = currentCoins >= theme.purchasePrice;
    final shortage = canAfford ? 0 : theme.purchasePrice - currentCoins;
    final remainingAfter = canAfford ? currentCoins - theme.purchasePrice : 0;

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
              _Header(
                onClose: () => Navigator.of(context)
                    .pop(ThemePurchaseChoice.cancel),
              ),
              SizedBox(height: 12.h),
              _Thumbnail(theme: theme),
              SizedBox(height: 16.h),
              Text(
                theme.themeName,
                textAlign: TextAlign.center,
                style: AppTextStyles.titleLarge.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                '${theme.furnitureCount}종 중 ${theme.ownedCount}종 보유',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              SizedBox(height: 14.h),
              _FurnitureList(theme: theme),
              SizedBox(height: 14.h),
              _PriceCard(
                totalPrice: theme.totalPrice,
                purchasePrice: theme.purchasePrice,
                remainingAfter: remainingAfter,
                shortage: shortage,
                canAfford: canAfford,
              ),
              SizedBox(height: 20.h),
              _ConfirmButton(
                canAfford: canAfford,
                onConfirm: () => Navigator.of(context)
                    .pop(ThemePurchaseChoice.purchaseAndPlace),
              ),
              SizedBox(height: 8.h),
              _PurchaseOnlyButton(
                canAfford: canAfford,
                onTap: () => Navigator.of(context)
                    .pop(ThemePurchaseChoice.purchaseOnly),
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
    return SizedBox(
      height: 40.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            '주문서 확인',
            style: AppTextStyles.titleMedium.copyWith(color: colors.textPrimary),
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

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.theme});

  final FurnitureTheme theme;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      height: 130.h,
      decoration: BoxDecoration(
        color: colors.streakCardBg,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: theme.thumbnailUrl.isEmpty
          ? Icon(
        Icons.collections_bookmark_outlined,
        size: 36.sp,
        color: colors.textHint,
      )
          : Image.network(
        theme.thumbnailUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, _, _) => Icon(
          Icons.broken_image_outlined,
          size: 32.sp,
          color: colors.textHint,
        ),
      ),
    );
  }
}

/// 테마에 포함된 가구 리스트. 행마다 카테고리 아이콘 + 이름 + 가격 + 보유 뱃지.
/// 8행을 넘는 테마는 박스 안에서 스크롤되도록 내부 ListView 로 감싸 외곽이
/// 다이얼로그 사이즈를 부풀리지 않게 한다.
class _FurnitureList extends StatelessWidget {
  const _FurnitureList({required this.theme});

  final FurnitureTheme theme;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final furnitures = theme.furnitures;
    if (furnitures.isEmpty) {
      // 방어적: 응답이 비어 있어도 다이얼로그가 깨지지 않게 폴백.
      return Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        alignment: Alignment.center,
        child: Text(
          '구성 가구 정보를 불러오지 못했어요',
          style: AppTextStyles.bodySmall.copyWith(color: colors.textHint),
        ),
      );
    }

    // 4행 이상이면 박스 안에서만 스크롤되도록 높이 제한 — 다이얼로그 전체가
    // 가구 리스트로 꽉 차는 인상을 줄여 결제 카드/CTA 까지 한눈에 들어오게 한다.
    // 4행 미만은 그대로 늘어나도록 height: null 처리.
    final showScroll = furnitures.length > 3;

    final body = ListView.separated(
      shrinkWrap: true,
      physics: showScroll
          ? const ClampingScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      itemCount: furnitures.length,
      separatorBuilder: (_, _) => Divider(height: 1, color: colors.border),
      itemBuilder: (_, i) => _FurnitureRow(furniture: furnitures[i]),
    );

    return Container(
      decoration: BoxDecoration(
        color: colors.streakCardBg,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: colors.border),
      ),
      child: ConstrainedBox(
        // 🛠 기존 168.h 에서 약 3행 크기인 126.h 로 최대 높이 축소!
        constraints: BoxConstraints(maxHeight: showScroll ? 126.h : double.infinity),
        child: body,
      ),
    );
  }
}

/// 구성 가구 한 행. 카테고리 칩(icon + 라벨) + 가구 이름 + 가격/보유 뱃지.
///
/// 칩은 PurchaseDialog 의 _CategoryChip 와 같은 톤 — 두 다이얼로그를 같은
/// 시각 언어로 묶기 위해. 이름은 길어도 자르지 않고 줄바꿈 — `maxLines`/`ellipsis`
/// 미적용. 한 행 높이가 가구별로 달라질 수 있으므로 칩과 가격은 위쪽 정렬한다.
class _FurnitureRow extends StatelessWidget {
  const _FurnitureRow({required this.furniture});

  final ThemeFurniture furniture;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final category = ShopCategory.fromServer(furniture.category);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CategoryChip(category: category),
          SizedBox(width: 10.w),
          Expanded(
            child: Padding(
              // 칩이 vertical: 4.h padding 을 갖고 있어 chip 베이스라인과 본문
              // 텍스트 베이스라인이 살짝 어긋나 보임 — 본문을 같은 양만큼 내려
              // 시각적으로 정렬한다.
              padding: EdgeInsets.only(top: 3.h),
              child: Text(
                furniture.name,
                style: AppTextStyles.bodySmall.copyWith(color: colors.textPrimary),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Padding(
            padding: EdgeInsets.only(top: 3.h),
            child: furniture.owned
                ? const _OwnedBadge()
                : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CoinIcon(size: 12.sp),
                SizedBox(width: 3.w),
                Text(
                  _formatCoins(furniture.price),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 한 가구가 어느 카테고리에 속하는지 한눈에 보여주는 작은 칩.
/// PurchaseDialog 의 동명 위젯과 같은 톤 — accent 14% 배경 + 굵은 라벨.
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category});

  final ShopCategory category;

  @override
  Widget build(BuildContext context) {
    final accent = shopCategoryAccent(category);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(category.icon, size: 12.sp, color: accent),
          SizedBox(width: 3.w),
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

class _OwnedBadge extends StatelessWidget {
  const _OwnedBadge();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        '보유',
        style: AppTextStyles.labelSmall.copyWith(
          color: colors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// 결제 금액(큰 글씨) + "구매 후 잔액"/"부족 코인" 부캡션을 묶은 카드.
/// PurchaseDialog 의 _PriceCard 와 동일 톤 — 사용자가 두 다이얼로그를 같은
/// 가격 박스로 인지하도록.
///
/// 정가가 결제가보다 크면 ("일부 보유" 케이스) 결제가 위에 정가를 작은 취소선
/// 으로 같이 보여줘 사용자가 "내가 보유한 가구만큼 빠진 금액이구나" 를 인지할 수
/// 있게 한다.
class _PriceCard extends StatelessWidget {
  const _PriceCard({
    required this.totalPrice,
    required this.purchasePrice,
    required this.remainingAfter,
    required this.shortage,
    required this.canAfford,
  });

  final int totalPrice;
  final int purchasePrice;
  final int remainingAfter;
  final int shortage;
  final bool canAfford;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final discounted = totalPrice > purchasePrice;
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
          if (discounted) ...[
            Text(
              '정가 ${_formatCoins(totalPrice)}',
              style: AppTextStyles.bodySmall.copyWith(
                color: colors.textHint,
                decoration: TextDecoration.lineThrough,
              ),
            ),
            SizedBox(height: 4.h),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CoinIcon(size: 22.sp),
              SizedBox(width: 6.w),
              Text(
                _formatCoins(purchasePrice),
                style: AppTextStyles.titleMedium.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          if (canAfford)
            _RemainingCaption(remainingAfter: remainingAfter)
          else
            _ShortageCaption(shortage: shortage),
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
  const _ConfirmButton({
    required this.canAfford,
    required this.onConfirm,
  });

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
            fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
          ),
        ),
        child: Text(canAfford ? '구매하고 바로 배치하기' : '코인이 부족해요'),
      ),
    );
  }
}

/// 가구 [PurchaseDialog] 의 동명 위젯과 같은 톤 — primary 와 위계를 분리하기
/// 위해 텍스트 버튼 + 보조 컬러로 그린다. 잔액 부족이면 함께 비활성화.
class _PurchaseOnlyButton extends StatelessWidget {
  const _PurchaseOnlyButton({required this.canAfford, required this.onTap});

  final bool canAfford;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: double.infinity,
      height: 30.h,
      child: TextButton(
        onPressed: canAfford ? onTap : null,
        style: TextButton.styleFrom(
          foregroundColor: colors.textSecondary,
          disabledForegroundColor: colors.textHint,
          textStyle: AppTextStyles.bodySmall.copyWith(
            fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
          ),        ),
        child: const Text('지금 배치하지 않고 구매만 하기'),
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
