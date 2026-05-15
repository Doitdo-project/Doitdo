import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'package:doitdo/core/network/api_response.dart';
import 'package:doitdo/data/models/furniture_shop_resp_dto.dart';
import 'package:doitdo/data/models/furniture_theme_resp_dto.dart';
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

  /// 가구 테마 목록. 상점의 "테마" 탭에서 카드로 노출한다.
  /// `is_active = true` 한정, `display_order ASC` 정렬은 BE 가 내려준 순서를 그대로 따른다.
  /// 응답에는 사용자별 보유/결제 메타(ownedCount, purchasePrice, alreadyOwned, furnitures[])
  /// 가 포함되어 카드 표시 + 구매 다이얼로그가 추가 호출 없이 열린다.
  @GET('/api/shop/themes')
  Future<ApiResponse<FurnitureThemeListRespDto>> listThemes();

  /// 테마 전체 방 미리보기. 단일 가구 [previewRoom] 의 세트 버전 — 테마에 속한
  /// 여러 카테고리 가구를 내 실제 방에 저장 없이 합성해서 돌려준다. 응답은
  /// 기존 [RoomRespDto] 와 동일하며, 테마 가구만 `preview=true` 로 표시된다.
  @GET('/api/shop/themes/{themeCode}/preview-room')
  Future<ApiResponse<RoomRespDto>> previewThemeRoom(
    @Path('themeCode') String themeCode,
  );

  /// 테마 세트 일괄 구매. 미보유 가구만 결제하고 자동 배치는 하지 않는다.
  /// `S03-003 THEME_EMPTY` / `S03-010 THEME_ALREADY_OWNED` /
  /// `S00-003 INSUFFICIENT_BALANCE` 가 주요 실패 분기.
  @POST('/api/shop/themes/{themeCode}/purchase')
  Future<ApiResponse<ThemePurchaseRespDto>> purchaseTheme(
    @Path('themeCode') String themeCode,
  );

  /// 보유한 테마 가구를 한 번에 방에 배치한다. 같은 카테고리 기존 배치는 자동
  /// 교체. 일부라도 미보유 가구가 있으면 `S03-011 THEME_NOT_FULLY_OWNED` —
  /// 호출자가 [purchaseTheme] 를 먼저 호출해야 한다.
  @POST('/api/users/me/room/themes/{themeCode}/placements')
  Future<ApiResponse<ThemePlacementRespDto>> placeTheme(
    @Path('themeCode') String themeCode,
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
