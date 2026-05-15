import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:doitdo/domain/entities/room_placement.dart';

/// `GET /api/users/me/room` 응답을 로컬에 영구 저장해 두는 가벼운 캐시.
///
/// 다음 콜드 스타트에서 [myRoomProvider] 가 네트워크 응답을 기다리지 않고 즉시
/// 캐시된 가구 배치를 emit 하도록 한다 (stale-while-revalidate). 캐시는
/// JSON 으로 저장되고 키 [_key] 에 매핑된다.
///
/// 캐시 무효화는 직접 [clear] 를 호출하거나, [save] 로 새 데이터를 덮어쓰면 된다.
/// 가구를 새로 배치/구매/삭제한 직후엔 자동으로 [MyRoomNotifier] 가 fresh fetch
/// 결과를 다시 [save] 하므로 별도 무효화는 필요 없다.
class RoomSnapshotCache {
  RoomSnapshotCache(this._prefs);

  final SharedPreferences _prefs;
  static const String _key = 'cache.my_room.v1';

  Future<void> save(List<RoomFurniturePlacement> placements) async {
    final list = placements.map(_toJson).toList(growable: false);
    await _prefs.setString(_key, jsonEncode(list));
  }

  /// 캐시가 없거나 파싱 실패 시 null. 호출자는 null 이면 네트워크 fetch 로 fallback.
  List<RoomFurniturePlacement>? read() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(_fromJson)
          .toList(growable: false);
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() => _prefs.remove(_key);

  Map<String, dynamic> _toJson(RoomFurniturePlacement p) => {
        'placementId': p.placementId,
        'userFurnitureId': p.userFurnitureId,
        'furnitureId': p.furnitureId,
        'name': p.name,
        'category': p.category,
        'imageUrl': p.imageUrl,
        'x': p.x,
        'y': p.y,
        'width': p.width,
        'height': p.height,
        'zIndex': p.zIndex,
        'rotation': p.rotation,
        'preview': p.preview,
      };

  RoomFurniturePlacement _fromJson(Map<String, dynamic> m) =>
      RoomFurniturePlacement(
        placementId: (m['placementId'] as num?)?.toInt(),
        userFurnitureId: (m['userFurnitureId'] as num?)?.toInt(),
        furnitureId: (m['furnitureId'] as num?)?.toInt() ?? 0,
        name: (m['name'] as String?) ?? '',
        category: (m['category'] as String?) ?? '',
        imageUrl: (m['imageUrl'] as String?) ?? '',
        x: (m['x'] as num?)?.toInt() ?? 0,
        y: (m['y'] as num?)?.toInt() ?? 0,
        width: (m['width'] as num?)?.toInt() ?? 0,
        height: (m['height'] as num?)?.toInt() ?? 0,
        zIndex: (m['zIndex'] as num?)?.toInt() ?? 0,
        rotation: (m['rotation'] as num?)?.toInt() ?? 0,
        preview: (m['preview'] as bool?) ?? false,
      );
}
