import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:doitdo/core/theme/app_colors.dart';
import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/pages/shop/shop_state.dart';
import 'package:doitdo/presentation/widgets/common/room_furniture_slots.dart';

/// 상점 상단의 "방 미리보기" 영역.
///
/// 다마고치 홈의 [RoomLayer] 와 동일한 슬롯 시스템 ([kRoomFurnitureSlots]) 을
/// 사용해 같은 구도를 작은 카드 안에 그대로 축소해서 보여준다.
/// 베이스 — `BACKGROUND` 카테고리 아이템을 `BoxFit.cover` 로 깔고, 그 위에 가구.
/// 배경/가구 이미지가 비어있거나 로드 실패 시 카테고리 accent 톤으로 폴백.
class ShopRoomPreview extends StatelessWidget {
  const ShopRoomPreview({super.key, required this.items});

  /// 방에 표시할 아이템들. 호출자가 placed + 미리보기 토글을 합성해서 넘긴다.
  final List<ShopItem> items;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final background = items
        .where((it) =>
            it.category == ShopCategory.background && it.imageUrl.isNotEmpty)
        .firstOrNull;
    final furniture = items
        .where((it) =>
            it.category != ShopCategory.background && it.imageUrl.isNotEmpty)
        .toList(growable: false);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        height: 180.h,
        decoration: BoxDecoration(
          color: colors.streakCardBg,
          border: Border.all(color: colors.border),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // 가구 캔버스를 디자인 기준 AR 로 잠가 디바이스 무관하게 동일 구도 유지
            // (룸 카드와 같은 정책, AR 만 다름). 배경은 카드 풀블리드.
            final canvas = computeRoomCanvasLayout(
              parentWidth: constraints.maxWidth,
              parentHeight: constraints.maxHeight,
              aspect: kShopPreviewCanvasAspect,
            );
            return Stack(
              children: [
                if (background != null)
                  Positioned.fill(
                    // 같은 카테고리(BG) 안에서 imageUrl 만 바뀔 때 Image 위젯이 새로
                    // 만들어지지 않도록 안정 key 지정. gaplessPlayback 으로 새 이미지
                    // 디코드 전까지 직전 프레임 유지 → 빈 박스 노출 방지.
                    child: Image.network(
                      background.imageUrl,
                      key: const ValueKey('shop-preview-bg'),
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      gaplessPlayback: true,
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                Positioned(
                  left: canvas.offsetX,
                  top: canvas.offsetY,
                  width: canvas.width,
                  height: canvas.height,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (final item in furniture)
                        _buildItem(item, canvas.width, canvas.height),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildItem(ShopItem item, double w, double h) {
    final slot = kRoomFurnitureSlots[item.category] ?? kRoomFurnitureFallbackSlot;
    final accent = _categoryAccent(item.category);
    // 카테고리별로 안정된 key — 같은 카테고리 슬롯 안에서 가구만 교체될 때
    // Image 위젯이 remount 되어 디코드를 다시 하는 일이 없도록 한다.
    // gaplessPlayback 으로 새 imageUrl 디코드가 끝나기 전까지 직전 프레임을 유지해
    // 빈 자리를 보이지 않게 한다.
    return Positioned(
      key: ValueKey('shop-preview-slot-${item.category.name}'),
      left: slot.left == null ? null : slot.left! * w,
      right: slot.right == null ? null : slot.right! * w,
      top: slot.top == null ? null : slot.top! * h,
      bottom: slot.bottom == null ? null : slot.bottom! * h,
      width: slot.width * w,
      height: slot.height * h,
      child: Image.network(
        item.imageUrl,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) =>
            Icon(item.category.icon, color: accent, size: 24.sp),
      ),
    );
  }
}

/// 더미 일러스트가 들어오기 전까지 카테고리별 톤을 분리해서 보여주기 위한 색.
/// 카드/다이얼로그/룸 미리보기 폴백 아이콘 컬러로 공유된다.
Color _categoryAccent(ShopCategory category) {
  switch (category) {
    case ShopCategory.background:
      return const Color(0xFFB69BD8);
    case ShopCategory.bed:
      return const Color(0xFFE48BA0);
    case ShopCategory.desk:
      return const Color(0xFF8E6E4A);
    case ShopCategory.window:
      return const Color(0xFF8FB3D4);
    case ShopCategory.clock:
      return const Color(0xFF6E8E7B);
    case ShopCategory.tv:
      return const Color(0xFF5A6470);
    case ShopCategory.plant:
      return const Color(0xFF6FA86F);
    case ShopCategory.rug:
      return const Color(0xFFD08AA0);
    case ShopCategory.etc:
      return AppColors.shopText;
  }
}

/// 외부 위젯에서도 카테고리 톤을 동일하게 쓸 수 있도록 노출.
Color shopCategoryAccent(ShopCategory category) => _categoryAccent(category);

class ShopRoomPreviewEmpty extends StatelessWidget {
  const ShopRoomPreviewEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      height: 180.h,
      decoration: BoxDecoration(
        color: colors.streakCardBg,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: colors.border),
      ),
      alignment: Alignment.center,
      child: Text(
        '아직 배치된 가구가 없어요',
        style: AppTextStyles.bodySmall.copyWith(color: colors.textHint),
      ),
    );
  }
}
