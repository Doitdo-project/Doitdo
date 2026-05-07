import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/domain/entities/room_placement.dart';
import 'package:doitdo/presentation/pages/tamagochi/my_room_provider.dart';

/// 다마고치 홈 캐릭터 카드의 방 배경 + 가구 합성 레이어.
///
/// `GET /api/users/me/room` 응답에서:
/// - `BACKGROUND` 카테고리는 카드를 꽉 채우는 베이스(`BoxFit.cover`).
/// - 그 외 가구는 서버가 내려준 `(x, y, width, height)` 를 무시하고
///   카테고리별 고정 슬롯에 비율 기반으로 배치한다. 픽셀 절댓값이 아니라
///   카드 width/height 의 비율이라 어떤 디바이스에서도 같은 구도가 나온다.
///
/// z-order: RoomLayer 가 가장 뒤다 (카드 상위 Stack 에서 캐릭터/말풍선/
/// 상점·도감 아이콘 → 그 바깥의 StatusPill 순으로 가구 위에 그려진다).
/// 가구가 EXP 바나 우측 아이콘 영역을 비주얼적으로 침범해도 자동으로 가려진다.
///
/// 알 수 없는 카테고리는 [_fallbackSlot] (카드 가운데) 으로 대피.
class RoomLayer extends ConsumerWidget {
  const RoomLayer({super.key});

  /// CharacterCard 가 캐릭터 bottom 정렬에 사용하는 값.
  static const double characterBottomInset = 70;

  /// 카테고리(서버 응답 대문자 문자열) → 카드 비율 기반 슬롯.
  /// `left`/`right`, `top`/`bottom` 은 한 쌍씩만 채운다.
  static const Map<String, _Slot> _slots = {
    'BED':    _Slot(left: 0.00, bottom: 0.00, width: 0.26, height: 0.36),
    'PLANT':  _Slot(right: 0.04, bottom: 0.04, width: 0.16, height: 0.40),
    'DESK':   _Slot(left: 0.60, bottom: 0.06, width: 0.36, height: 0.32),
    'RUG':      _Slot(left: 0.18, bottom: 0.02, width: 0.64, height: 0.18),
    'WARDROBE': _Slot(right: 0.04, bottom: 0.04, width: 0.22, height: 0.18),
    'WINDOW':  _Slot(right: 0.16, top: 0.00, width: 0.32, height: 0.46),
    'CLOCK': _Slot(left: 0.10, top: 0.08, width: 0.18, height: 0.20),
    'TV':     _Slot(left: 0.32, top: 0.18, width: 0.40, height: 0.32),
  };

  static const _Slot _fallbackSlot =
      _Slot(left: 0.30, top: 0.35, width: 0.30, height: 0.30);

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
                  alignment: Alignment.center,
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
    final slot = _slots[item.category.toUpperCase()] ?? _fallbackSlot;
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

@immutable
class _Slot {
  const _Slot({
    this.left,
    this.right,
    this.top,
    this.bottom,
    required this.width,
    required this.height,
  });

  final double? left;
  final double? right;
  final double? top;
  final double? bottom;
  final double width;
  final double height;
}
