import 'package:doitdo/core/network/base_repository.dart';
import 'package:doitdo/data/datasources/character_api.dart';
import 'package:doitdo/domain/entities/character.dart';
import 'package:doitdo/domain/repositories/character_repository.dart';
import 'package:doitdo/presentation/models/collection_entry.dart';

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

  @override
  Future<Character> renameCharacter(String name) => safeApiCall(
        () => _api.renameCharacter({'name': name}),
      ).then((dto) => dto.toEntity());

  @override
  Future<void> evolveCharacter(int userCharacterId) =>
      safeApiCall(() => _api.evolveCharacter(userCharacterId));

  @override
  Future<List<CollectionEntry>> getEncyclopedia() => safeApiCall(
        () => _api.getEncyclopedia(),
      ).then((dto) => dto.items.map((item) => item.toEntry()).toList());

  @override
  Future<EncyclopediaDetail> getEncyclopediaDetail(String species) =>
      safeApiCall(() => _api.getEncyclopediaDetail(species))
          .then((dto) => dto.toEntity());

  @override
  Future<void> approveFarewell({required bool approved}) =>
      safeApiCall(() => _api.approveFarewell({'approved': approved}));
}