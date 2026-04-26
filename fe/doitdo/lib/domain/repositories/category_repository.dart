import 'package:doitdo/data/models/category_dto.dart';

abstract class CategoryRepository {
  Future<List<CategoryResp>> getCategories();

  Future<CategoryResp> createCategory({
    required String name,
    required int colorId,
  });

  Future<CategoryResp> updateCategory({
    required int categoryId,
    String? name,
    int? colorId,
  });

  Future<void> deleteCategory(int categoryId);

  /// 전체 팔레트 목록 조회 (카테고리 색상 피커용).
  Future<PaletteListResp> getPalettes();
}
