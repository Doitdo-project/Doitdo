import 'package:doitdo/core/network/base_repository.dart';
import 'package:doitdo/data/datasources/shop_api.dart';
import 'package:doitdo/domain/entities/furniture_theme.dart';
import 'package:doitdo/domain/entities/room_placement.dart';
import 'package:doitdo/domain/entities/shop_entry.dart';
import 'package:doitdo/domain/entities/shop_furniture.dart';
import 'package:doitdo/domain/entities/user_furniture.dart';
import 'package:doitdo/domain/repositories/shop_repository.dart';

class ShopRepositoryImpl extends BaseRepository implements ShopRepository {
  ShopRepositoryImpl(this._api);

  final ShopApi _api;

  @override
  Future<ShopEntry> getShopEntry({String? category}) =>
      safeApiCall(() => _api.getShopEntry(category: category))
          .then((dto) => dto.toEntity());

  @override
  Future<List<FurnitureShopItem>> listFurnitures({String? category}) =>
      safeApiCall(() => _api.listFurnitures(category: category))
          .then((dto) => dto.toEntities());

  @override
  Future<FurniturePurchaseResult> purchaseFurniture(int furnitureId) =>
      safeApiCall(() => _api.purchaseFurniture(furnitureId))
          .then((dto) => dto.toEntity());

  @override
  Future<List<UserFurnitureItem>> listMyFurnitures() =>
      safeApiCall(() => _api.listMyFurnitures()).then((dto) => dto.toEntities());

  @override
  Future<List<RoomFurniturePlacement>> previewRoom(int furnitureId) =>
      safeApiCall(() => _api.previewRoom(furnitureId))
          .then((dto) => dto.toEntities());

  @override
  Future<List<FurnitureTheme>> listThemes() =>
      safeApiCall(() => _api.listThemes()).then((dto) => dto.toEntities());

  @override
  Future<List<RoomFurniturePlacement>> previewThemeRoom(String themeCode) =>
      safeApiCall(() => _api.previewThemeRoom(themeCode))
          .then((dto) => dto.toEntities());

  @override
  Future<ThemePurchaseResult> purchaseTheme(String themeCode) =>
      safeApiCall(() => _api.purchaseTheme(themeCode))
          .then((dto) => dto.toEntity());

  @override
  Future<ThemePlacementResult> placeTheme(String themeCode) =>
      safeApiCall(() => _api.placeTheme(themeCode))
          .then((dto) => dto.toEntity());

  @override
  Future<List<RoomFurniturePlacement>> getMyRoom() =>
      safeApiCall(() => _api.getMyRoom()).then((dto) => dto.toEntities());

  @override
  Future<RoomFurniturePlacement> placeFurniture(int userFurnitureId) =>
      safeApiCall(() => _api.placeFurniture(userFurnitureId))
          .then((dto) => dto.toEntity());

  @override
  Future<RoomFurniturePlacement> updatePlacement({
    required int placementId,
    int? x,
    int? y,
    int? zIndex,
    int? rotation,
  }) {
    // null 필드는 body 에서 제외해 서버가 partial update 를 받게 한다.
    final body = <String, dynamic>{
      'x': ?x,
      'y': ?y,
      'zIndex': ?zIndex,
      'rotation': ?rotation,
    };
    return safeApiCall(() => _api.updatePlacement(placementId, body))
        .then((dto) => dto.toEntity());
  }

  @override
  Future<void> removePlacement(int placementId) =>
      safeApiCallNoData(() => _api.removePlacement(placementId));
}
