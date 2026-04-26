import 'package:dio/dio.dart';

import 'package:doitdo/core/errors/exceptions.dart';
import 'package:doitdo/core/network/base_repository.dart';
import 'package:doitdo/core/network/dio_error_mapper.dart';
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

  /// `/api/palettes` 는 envelope 의 `data` 가 List 라 retrofit 자동 디코드가 안 된다.
  /// raw `Future<dynamic>` 으로 envelope 를 그대로 받아 수동으로 파싱.
  @override
  Future<PaletteListResp> getPalettes() async {
    try {
      final raw = await _api.getPalettesRaw();
      if (raw is! Map<String, dynamic>) {
        throw const ServerException('팔레트 응답 형식이 올바르지 않습니다.');
      }
      final status = (raw['status'] as num?)?.toInt() ?? -1;
      if (status < 200 || status >= 300) {
        throw ServerException(
          (raw['message'] as String?) ?? '팔레트 조회 실패',
          statusCode: status,
        );
      }
      return PaletteListResp.fromJson(raw['data']);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}
