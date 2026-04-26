import 'package:doitdo/core/network/base_repository.dart';
import 'package:doitdo/data/datasources/category_api.dart';
import 'package:doitdo/data/models/category_dto.dart';
import 'package:doitdo/domain/repositories/category_repository.dart';

class CategoryRepositoryImpl extends BaseRepository
    implements CategoryRepository {
  CategoryRepositoryImpl(this._api);

  final CategoryApi _api;

  @override
  Future<List<CategoryResp>> getCategories() =>
      safeApiCall(() => _api.getCategories()).then((resp) => resp.items);

  @override
  Future<CategoryResp> createCategory({
    required String name,
    required int colorId,
  }) =>
      safeApiCall(
        () => _api.createCategory({'name': name, 'colorId': colorId}),
      );

  @override
  Future<CategoryResp> updateCategory({
    required int categoryId,
    String? name,
    int? colorId,
  }) =>
      safeApiCall(
        () => _api.updateCategory(
          categoryId,
          {
            if (name != null) 'name': name,
            if (colorId != null) 'colorId': colorId,
          },
        ),
      );

  @override
  Future<void> deleteCategory(int categoryId) => safeApiCallVoid(
        () => _api.deleteCategory(categoryId),
      );

  @override
  Future<PaletteListResp> getPalettes() =>
      safeApiCall(() => _api.getPalettes());
}
