import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/domain/entities/room_placement.dart';
import 'package:doitdo/presentation/pages/tamagochi/my_room_provider.dart';

/// 다마고치 홈 캐릭터 카드의 방 배경 레이어.
///
/// `GET /api/users/me/room` 응답에서 `BACKGROUND` 카테고리 항목 하나만 골라
/// 그 `imageUrl` 을 그대로 띄운다. 좌표/크기/zIndex 등 가구 배치 정보는
/// 무시한다 — 다른 가구는 추후 로컬 고정 좌표로 별도 처리.
///
/// 로딩 / 에러 / BG 없음 상태에서는 아무것도 그리지 않는다.
class RoomLayer extends ConsumerWidget {
  const RoomLayer({super.key});

  /// CharacterCard 가 캐릭터 bottom 정렬에 사용하는 값.
  static const double characterBottomInset = 70;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRoom = ref.watch(myRoomProvider);
    final items = asyncRoom.valueOrNull ?? const <RoomFurniturePlacement>[];
    final background = items
        .where((item) =>
            item.category.toUpperCase() == 'BACKGROUND' &&
            item.imageUrl.isNotEmpty)
        .firstOrNull;
    if (background == null) return const SizedBox.shrink();
    return Image.network(
      background.imageUrl,
      // 카드 영역을 꽉 채우도록 비율 유지하며 확대/축소. 가운데 정렬이라
      // 카드 비율과 사진 비율이 다르면 길어진 변(보통 위/아래 또는 좌/우) 이
      // 살짝 잘린다. 직접 조정하고 싶으면 alignment 또는 fit 을 바꿔보세요.
      fit: BoxFit.cover,
      alignment: Alignment.center,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
  }
}
