import 'package:doitdo/domain/entities/character.dart';

const Set<int> kCharacterEyeAssetIds = {
  4,
  5,
  6,
  7,
  8,
  9,
  10,
  11,
  12,
  16,
  17,
  18,
  58,
  59,
  60,
  62,
  63,
  64,
  66,
  67,
  68,
  70,
  71,
  72,
  74,
  75,
  76,
};

const Set<int> kCharacterEyeVariantAssetIds = {9, 18};
const Set<int> kCharacterIdleAssetIds = {
  4,
  5,
  6,
  7,
  8,
  9,
  10,
  11,
  12,
  16,
  17,
  18,
  58,
  59,
  60,
  62,
  63,
  64,
  66,
  67,
  68,
  70,
  71,
  72,
  74,
  75,
  76,
};
const Set<int> kCharacterWalkAssetIds = {6, 9, 18, 60, 64, 68, 72, 76};
const Set<int> kCharacterWalkIntroAssetIds = {6, 18, 68};
const Set<int> kCharacterWalkOutroAssetIds = {6, 18, 68};
const Set<int> kHorizontalWalkCharacterIds = {6, 12, 18};
const Set<int> kNaturalFacingWalkCharacterIds = {6};
const Set<int> kReverseFacingWalkCharacterIds = {12};

String? resolveLocalCharacterActionAsset({
  required int? characterId,
  required String actionType,
}) {
  final id = characterId;
  if (id == null) return null;

  switch (actionType.trim().toUpperCase()) {
    case 'EYE':
      return kCharacterEyeAssetIds.contains(id)
          ? 'assets/animations/eye/$id.gif'
          : null;
    case 'IDLE':
      return kCharacterIdleAssetIds.contains(id)
          ? 'assets/animations/idle/$id.gif'
          : null;
    case 'WALK':
      return kCharacterWalkAssetIds.contains(id)
          ? 'assets/animations/walk/$id.gif'
          : null;
    case 'SLEEP':
    case 'HAPPY':
    case 'SAD':
    case 'POOP':
      return null;
    default:
      return null;
  }
}

String? resolveLocalCharacterActionAssetByEnum({
  required int? characterId,
  required CharacterAction action,
}) {
  return resolveLocalCharacterActionAsset(
    characterId: characterId,
    actionType: action.serverValue,
  );
}
