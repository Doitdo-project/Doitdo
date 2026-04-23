import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'package:doitdo/core/network/api_response.dart';
import 'package:doitdo/data/models/character_dto.dart';

part 'character_api.g.dart';

/// `/api/characters/*` 엔드포인트 그룹.
///
/// envelope(`{status, message, data}`) 은 [ApiResponse] 로 감싸고 RepositoryImpl
/// 의 `safeApiCall` 이 벗겨낸다. 새 엔드포인트 추가 후에는:
///   dart run build_runner build --delete-conflicting-outputs
@RestApi()
abstract class CharacterApi {
  factory CharacterApi(Dio dio, {String baseUrl}) = _CharacterApi;

  /// 회원가입 직후 최초 캐릭터(알) 1회 수령.
  @POST('/api/characters/me')
  Future<ApiResponse<CharacterDto>> receiveEgg();

  /// 현재 사용자의 캐릭터 조회.
  @GET('/api/characters/me')
  Future<ApiResponse<CharacterDto>> getMyCharacter();

  /// 알을 10회 두드린 뒤 호출. 성공 시 부화된 캐릭터를 반환한다고 가정.
  @POST('/api/characters/me/hatch')
  Future<ApiResponse<CharacterDto>> hatchEgg();
}