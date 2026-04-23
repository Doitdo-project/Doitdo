import 'package:doitdo/core/network/base_repository.dart';
import 'package:doitdo/data/datasources/character_api.dart';
import 'package:doitdo/domain/entities/character.dart';
import 'package:doitdo/domain/repositories/character_repository.dart';

class CharacterRepositoryImpl extends BaseRepository
    implements CharacterRepository {
  CharacterRepositoryImpl(this._api);

  final CharacterApi _api;

  @override
  Future<Character> receiveEgg() =>
      safeApiCall(() => _api.receiveEgg()).then((dto) => dto.toEntity());

  @override
  Future<Character> getMyCharacter() =>
      safeApiCall(() => _api.getMyCharacter()).then((dto) => dto.toEntity());

  @override
  Future<Character> hatchEgg() =>
      safeApiCall(() => _api.hatchEgg()).then((dto) => dto.toEntity());
}