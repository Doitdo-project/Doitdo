import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/domain/entities/room_placement.dart';
import 'package:doitdo/presentation/pages/shop/shop_state.dart';
import 'package:doitdo/presentation/pages/tamagochi/my_room_provider.dart';
import 'package:doitdo/presentation/widgets/common/room_furniture_slots.dart';

/// 다마고치 홈 캐릭터 카드의 방 배경 + 가구 합성 레이어.
///
/// `GET /api/users/me/room` 응답에서:
/// - `BACKGROUND` 카테고리는 카드를 꽉 채우는 베이스(`BoxFit.cover`).
/// - 그 외 가구는 서버가 내려준 `(x, y, width, height)` 를 무시하고
///   [kRoomFurnitureSlots] (상점 미리보기와 공유) 의 비율 슬롯에 배치한다.
///   픽셀 절댓값이 아니라 카드 width/height 의 비율이라 어떤 디바이스에서도
///   같은 구도가 나온다.
///
/// z-order: RoomLayer 가 가장 뒤다 (카드 상위 Stack 에서 캐릭터/말풍선/
/// 상점·도감 아이콘 → 그 바깥의 StatusPill 순으로 가구 위에 그려진다).
/// 가구가 EXP 바나 우측 아이콘 영역을 비주얼적으로 침범해도 자동으로 가려진다.
class RoomLayer extends ConsumerWidget {
  const RoomLayer({super.key});

  /// CharacterCard 가 캐릭터 bottom 정렬에 사용하는 값.
  static const double characterBottomInset = 70;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRoom = ref.watch(myRoomProvider);
    final items = asyncRoom.valueOrNull ?? const <RoomFurniturePlacement>[];
    if (items.isEmpty) return const SizedBox.shrink();

    final background = items
        .where((it) =>
            it.category.toUpperCase() == 'BACKGROUND' && it.imageUrl.isNotEmpty)
        .firstOrNull;
    final furniture = items
        .where((it) =>
            it.category.toUpperCase() != 'BACKGROUND' && it.imageUrl.isNotEmpty)
        .toList(growable: false);

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return Stack(
          children: [
            if (background != null)
              Positioned.fill(
                child: Image.network(
                  background.imageUrl,
                  fit: BoxFit.cover,
                  // cover 가 박스 비율과 안 맞는 쪽을 잘라낼 때, 이미지 윗부분이
                  // 더 보이도록 anchor 를 위로 이동 (-1 = top, 0 = center).
                  alignment: const Alignment(0, -0.5),
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            for (final item in furniture) _buildItem(item, w, h),
          ],
        );
      },
    );
  }

  Widget _buildItem(RoomFurniturePlacement item, double w, double h) {
    final cat = ShopCategory.fromServer(item.category);
    final slot = kRoomFurnitureSlots[cat] ?? kRoomFurnitureFallbackSlot;
    return Positioned(
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
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
    );
  }
}
