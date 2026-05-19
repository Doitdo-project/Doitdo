import 'package:doitdo/core/theme/app_colors.dart';
import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/pages/shop/shop_state.dart';
import 'package:doitdo/presentation/widgets/common/room_furniture_slots.dart';
import 'package:doitdo/presentation/widgets/common/room_scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Shop room preview. Uses the same [RoomScene] renderer as the tamagochi home
/// room so background crop, canvas aspect, and furniture slots match.
class ShopRoomPreview extends StatelessWidget {
  const ShopRoomPreview({super.key, required this.items});

  final List<ShopItem> items;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final background = items
        .where(
          (it) =>
              it.category == ShopCategory.background && it.imageUrl.isNotEmpty,
        )
        .firstOrNull;
    final furniture = items
        .where(
          (it) =>
              it.category != ShopCategory.background && it.imageUrl.isNotEmpty,
        )
        .toList(growable: false);

    return AspectRatio(
      aspectRatio: computeRoomFrameAspect(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          decoration: BoxDecoration(
            color: colors.streakCardBg,
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: RoomScene(
            backgroundUrl: background?.imageUrl,
            items: [
              for (final item in furniture)
                RoomSceneItem(category: item.category, imageUrl: item.imageUrl),
            ],
          ),
        ),
      ),
    );
  }
}

class ShopRoomPreviewEmpty extends StatelessWidget {
  const ShopRoomPreviewEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AspectRatio(
      aspectRatio: computeRoomFrameAspect(context),
      child: Container(
        decoration: BoxDecoration(
          color: colors.streakCardBg,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: colors.border),
        ),
        alignment: Alignment.center,
        child: Text(
          '아직 배치한 가구가 없어요',
          style: AppTextStyles.bodySmall.copyWith(color: colors.textHint),
        ),
      ),
    );
  }
}

Color shopCategoryAccent(ShopCategory category) {
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
