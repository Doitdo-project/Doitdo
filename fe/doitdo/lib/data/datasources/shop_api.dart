import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'package:doitdo/core/network/api_response.dart';
import 'package:doitdo/data/models/furniture_shop_resp_dto.dart';
import 'package:doitdo/data/models/purchase_furniture_resp_dto.dart';
import 'package:doitdo/data/models/room_resp_dto.dart';
import 'package:doitdo/data/models/shop_entry_resp_dto.dart';
import 'package:doitdo/data/models/user_furniture_resp_dto.dart';

part 'shop_api.g.dart';

/// 상점 / 보유 가구 / 방 배치 엔드포인트 그룹.
///
/// envelope (`{status, message, data}`) 은 [ApiResponse] 로 감싸고 RepositoryImpl
/// 의 `safeApiCall` 이 벗겨낸다. 새 엔드포인트 추가 후에는:
///   dart run build_runner build --delete-conflicting-outputs
///
/// PATCH 요청 body 는 별도 freezed DTO 대신 `Map<String, dynamic>` 으로 직접
/// 보낸다 (renameCharacter 와 동일 패턴) — 4 개 필드 모두 nullable 부분 업데이트
/// 라 freezed 까지 끌어들이는 것보다 간결.
@RestApi()
abstract class ShopApi {
  factory ShopApi(Dio dio, {String baseUrl}) = _ShopApi;

  /// 상점 진입 시 가구 목록 + 내 방 배치를 한 번에 조회.
  @GET('/api/shop/entry')
  Future<ApiResponse<ShopEntryRespDto>> getShopEntry({
    @Query('category') String? category,
  });

  /// 상점 가구 목록. category 가 있으면 해당 카테고리만.
  @GET('/api/shop/furnitures')
  Future<ApiResponse<FurnitureShopRespDto>> listFurnitures({
    @Query('category') String? category,
  });

  /// 가구 구매. 잔액/중복/판매여부는 서버에서 검증되며 실패 시 4xx 로 떨어진다.
  @POST('/api/shop/furnitures/{furnitureId}/purchase')
  Future<ApiResponse<PurchaseFurnitureRespDto>> purchaseFurniture(
    @Path('furnitureId') int furnitureId,
  );

  /// 내가 보유 중인 가구 전체 목록.
  @GET('/api/users/me/furnitures')
  Future<ApiResponse<UserFurnitureRespDto>> listMyFurnitures();

  /// 가구 방 미리보기. 실제 저장은 일어나지 않으며 [RoomRespDto.items] 에는
  /// 같은 카테고리 기존 배치가 빠지고 대상 가구가 `preview=true` 로 들어온다.
  @GET('/api/shop/furnitures/{furnitureId}/preview-room')
  Future<ApiResponse<RoomRespDto>> previewRoom(
    @Path('furnitureId') int furnitureId,
  );

  /// 내 방 현재 배치.
  @GET('/api/users/me/room')
  Future<ApiResponse<RoomRespDto>> getMyRoom();

  /// 보유 가구를 방에 배치. 같은 카테고리 기존 배치는 서버가 알아서 교체한다.
  @POST('/api/users/me/room/furnitures/{userFurnitureId}/placements')
  Future<ApiResponse<RoomFurniturePlacementDto>> placeFurniture(
    @Path('userFurnitureId') int userFurnitureId,
  );

  /// 배치 가구 위치/회전 수정. body 는 `{x, y, zIndex, rotation}` 부분 업데이트.
  @PATCH('/api/users/me/room/placements/{placementId}')
  Future<ApiResponse<RoomFurniturePlacementDto>> updatePlacement(
    @Path('placementId') int placementId,
    @Body() Map<String, dynamic> body,
  );

  /// 배치만 제거 (보유 가구는 그대로 남는다). 응답 body 없음.
  @DELETE('/api/users/me/room/placements/{placementId}')
  Future<ApiResponse<ApiVoid>> removePlacement(
    @Path('placementId') int placementId,
  );
}
