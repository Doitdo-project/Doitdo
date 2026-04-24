import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'package:doitdo/core/network/api_response.dart';
import 'package:doitdo/data/models/character_dto.dart';
import 'package:doitdo/data/models/encyclopedia_dto.dart';
import 'package:doitdo/data/models/evolution_dto.dart';

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
  @POST('/api/characters/me/egg')
  Future<ApiResponse<CharacterDto>> receiveEgg();

  /// 현재 사용자의 캐릭터 조회.
  @GET('/api/characters/me')
  Future<ApiResponse<CharacterDto>> getMyCharacter();

  /// 알을 10회 두드린 뒤 호출. 성공 시 부화된 캐릭터를 반환한다고 가정.
  @POST('/api/characters/me/hatch')
  Future<ApiResponse<CharacterDto>> hatchEgg();

  /// 이름짓기 화면 제출 시 호출. body 는 {"name": "..."}.
  /// 응답은 갱신된 캐릭터(DTO).
  @PATCH('/api/characters/me/name')
  Future<ApiResponse<CharacterDto>> renameCharacter(
    @Body() Map<String, dynamic> body,
  );

  /// 성장률 100% 도달 시 호출. 진화 연출/전환 정보만 내려오고, 갱신된 캐릭터
  /// 정보는 [getMyCharacter] 로 다시 당긴다.
  @POST('/api/characters/{userCharacterId}/evolution')
  Future<ApiResponse<EvolutionDto>> evolveCharacter(
    @Path('userCharacterId') int userCharacterId,
  );

  /// 도감 목록. `{ items: [...] }` 형태.
  @GET('/api/characters/encyclopedia')
  Future<ApiResponse<EncyclopediaDto>> getEncyclopedia();
}