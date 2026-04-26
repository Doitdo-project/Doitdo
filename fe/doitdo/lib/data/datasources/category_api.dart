import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'package:doitdo/core/network/api_response.dart';
import 'package:doitdo/data/models/category_dto.dart';

part 'category_api.g.dart';

@RestApi()
abstract class CategoryApi {
  factory CategoryApi(Dio dio, {String baseUrl}) = _CategoryApi;

  // [T10] 카테고리 목록 조회
  @GET('/api/categories')
  Future<ApiResponse<CategoryListResp>> getCategories();

  // [T10] 카테고리 생성 (최대 6개)
  @POST('/api/categories')
  Future<ApiResponse<CategoryResp>> createCategory(
    @Body() Map<String, dynamic> body,
  );

  // [T12] 카테고리 수정 (이름·색상 부분 수정)
  @PATCH('/api/categories/{categoryId}')
  Future<ApiResponse<CategoryResp>> updateCategory(
    @Path('categoryId') int categoryId,
    @Body() Map<String, dynamic> body,
  );

  // [T11] 카테고리 삭제 (하드 삭제, 고정 카테고리 불가)
  // Future<void> 사용 이유: 서버가 204 No Content 로 body 없이 응답하므로
  // ApiResponse 파싱 자체를 하지 않아야 한다.
  @DELETE('/api/categories/{categoryId}')
  Future<void> deleteCategory(
    @Path('categoryId') int categoryId,
  );

  // [팔레트] 전체 팔레트 목록 조회 — 카테고리 색상 피커에 사용.
  // data 가 List 이므로 PaletteListResp 래퍼로 감싼다.
  @GET('/api/palettes')
  Future<ApiResponse<PaletteListResp>> getPalettes();
}
