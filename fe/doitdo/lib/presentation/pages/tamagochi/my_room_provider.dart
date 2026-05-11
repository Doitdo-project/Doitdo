import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/domain/entities/room_placement.dart';
import 'package:doitdo/presentation/providers/app_data_providers.dart';

/// 내 방 배치 조회 provider — `GET /api/users/me/room` 결과를 그대로 노출.
///
/// 다마고치 홈의 방 배경 / 가구 레이어가 구독한다. 가구를 새로 배치/이동/제거
/// 한 직후엔 `ref.invalidate(myRoomProvider)` 로 강제 재조회해 변경이 즉시
/// 반영되도록 한다.
final myRoomProvider =
    FutureProvider.autoDispose<List<RoomFurniturePlacement>>((ref) async {
  final repo = ref.watch(shopRepositoryProvider);
  return repo.getMyRoom();
});
