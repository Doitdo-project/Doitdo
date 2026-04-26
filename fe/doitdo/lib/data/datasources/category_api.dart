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
  //
  // 다른 엔드포인트와 다르게 envelope 의 `data` 가 **List** 라
  // (`{status, message, data: [{...}, ...]}`), retrofit_generator 가
  // 자동으로 만드는 `data as Map<String, dynamic>` 캐스트가 실패한다.
  // 또 `Map<String, dynamic>` 시그니처로 받아도 generator 가 value 마다
  // `dynamic.fromJson()` 같은 무효한 코드를 만들어 빌드 자체가 깨진다.
  //
  // 따라서 가장 안전하게 `Future<dynamic>` 으로 raw 디코드 결과를 받아,
  // Repository 에서 envelope 째 직접 파싱해 [PaletteListResp] 로 변환한다.
  @GET('/api/palettes')
  Future<dynamic> getPalettesRaw();
}
