import 'package:doitdo/domain/entities/room_placement.dart';
import 'package:doitdo/domain/entities/shop_entry.dart';
import 'package:doitdo/domain/entities/shop_furniture.dart';
import 'package:doitdo/domain/entities/user_furniture.dart';

/// 상점 / 보유 가구 / 방 배치 도메인 추상화.
///
/// 모든 메서드는 envelope 이 벗겨진 도메인 엔티티를 반환한다. 서버 검증 실패
/// (잔액 부족 / 중복 보유 등) 는 [ServerException] 으로 throw 되어 ViewModel
/// 이 사용자 메시지로 변환한다.
abstract class ShopRepository {
  /// 상점 진입 페이로드 (가구 목록 + 내 방 배치 합본).
  /// [category] 가 비어있지 않으면 해당 카테고리 가구만 받는다.
  Future<ShopEntry> getShopEntry({String? category});

  /// 상점 가구 목록.
  Future<List<FurnitureShopItem>> listFurnitures({String? category});

  /// 가구 구매. 성공 시 차감 후 잔액과 새 보유 가구 ID 가 함께 돌아온다.
  Future<FurniturePurchaseResult> purchaseFurniture(int furnitureId);

  /// 내가 보유 중인 가구.
  Future<List<UserFurnitureItem>> listMyFurnitures();

  /// 가구 미리보기. 실제 저장은 발생하지 않는다.
  /// `preview=true` 인 항목이 미리보기 대상이다.
  Future<List<RoomFurniturePlacement>> previewRoom(int furnitureId);

  /// 내 방 현재 배치 조회.
  Future<List<RoomFurniturePlacement>> getMyRoom();

  /// 보유 가구를 방에 배치. 같은 카테고리 기존 배치는 서버가 교체한다.
  Future<RoomFurniturePlacement> placeFurniture(int userFurnitureId);

  /// 배치 위치/회전 수정. 모든 인자는 nullable — 보낸 값만 갱신된다.
  Future<RoomFurniturePlacement> updatePlacement({
    required int placementId,
    int? x,
    int? y,
    int? zIndex,
    int? rotation,
  });

  /// 배치 제거 (보유 가구는 유지).
  Future<void> removePlacement(int placementId);
}
