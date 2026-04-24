import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/core/errors/exceptions.dart';
import 'package:doitdo/core/utils/app_logger.dart';
import 'package:doitdo/domain/entities/character.dart';
import 'package:doitdo/domain/repositories/character_repository.dart';
import 'package:doitdo/presentation/providers/app_data_providers.dart';

/// 현재 사용자의 캐릭터 상태.
///
/// `AsyncValue<Character?>` 로 표현:
/// - `loading`: 조회 중
/// - `data(null)`: 아직 알을 수령하지 않음 → UI 에서 "알 받기" CTA 노출
/// - `data(Character)`: 수령 완료 (알/부화 여부는 `character.isEgg`)
/// - `error`: 복구 불가능한 네트워크/서버 오류 (재시도 UX 대상)
class CharacterViewModel extends StateNotifier<AsyncValue<Character?>> {
  CharacterViewModel(this._repository) : super(const AsyncValue.loading());

  final CharacterRepository _repository;

  /// 현재 캐릭터 조회.
  ///
  /// 서버가 "미수령" 상태를 어떤 에러 코드로 내려줄지 명세가 확정되지 않아,
  /// 여기서는 [ServerException] 전체를 "미수령" 으로 해석한다. 추후 404 코드가
  /// 확정되면 `e.statusCode == 404` 만 미수령으로 좁히는 게 바람직하다.
  /// [UnauthorizedException] / 네트워크 타임아웃 등은 진짜 에러로 올린다.
  ///
  /// `copyWithPrevious` 로 직전 값을 유지한 채 isLoading 만 true 로 돌리므로,
  /// UI 는 이전 캐릭터 정보를 계속 표시하면서 위에 작은 로딩 인디케이터만 얹으면
  /// 된다 (진화/부화/독립 중 chrome 이 통째로 사라지는 깜빡임 방지).
  Future<void> load() async {
    state = const AsyncValue<Character?>.loading().copyWithPrevious(state);
    try {
      final character = await _repository.getMyCharacter();
      state = AsyncValue.data(character);
    } on ServerException catch (e) {
      appLogger.d('character not yet received (server ${e.statusCode})');
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// [load] 의 조용한 변형. state 를 loading 으로 먼저 전환하지 않고, 성공 시에만
  /// data 로 갱신한다. todo 완료 후 exp 반영 체크처럼 사용자에게 로딩 스피너를
  /// 보일 필요가 없는 백그라운드 리프레시에 사용. 실패 시 기존 상태를 유지하고
  /// 로그만 남긴다.
  Future<void> refresh() async {
    try {
      final character = await _repository.getMyCharacter();
      state = AsyncValue.data(character);
    } on ServerException catch (e) {
      appLogger.d('character refresh: server ${e.statusCode} (silent)');
    } catch (e, st) {
      appLogger.e('character refresh failed', error: e, stackTrace: st);
    }
  }

  /// 알 1회 수령. 완료 후 state 는 data(character) 로 전환된다.
  Future<void> receiveEgg() async {
    state = const AsyncValue<Character?>.loading().copyWithPrevious(state);
    try {
      final character = await _repository.receiveEgg();
      state = AsyncValue.data(character);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 로그인 직후 호출. GET → 미수령이면 POST 로 자동 수령.
  /// 이미 받은 사용자든 신규든 한 번 부르면 캐릭터가 채워진 상태가 된다.
  Future<void> ensureCharacter() async {
    await load();
    final current = state;
    final hasNoCharacter =
        current is AsyncData<Character?> && current.value == null;
    if (hasNoCharacter) {
      await receiveEgg();
    }
  }

  /// 알 10회 탭 후 호출. 성공하면 true, 실패해도 이전 상태(알)는 유지한다.
  /// 에러 스낵바는 호출자가 띄운다.
  ///
  /// hatch 응답은 characterId/stage/name/thumbnailUrl 만 내려주기 때문에
  /// userCharacterId / growthPercent 가 비어있다. 진화 API 호출에 userCharacterId
  /// 가 필요하므로 성공 직후 GET /api/characters/me 로 전체 정보를 재조회한다.
  Future<bool> hatchEgg() async {
    try {
      await _repository.hatchEgg();
      await load();
      return true;
    } catch (e, st) {
      appLogger.e('hatch failed', error: e, stackTrace: st);
      return false;
    }
  }

  /// 이름짓기 화면 제출. 성공 시 이름 반영된 캐릭터로 state 갱신.
  ///
  /// rename 응답도 hatch 와 동일하게 characterId/name 2 필드만 내려주므로
  /// 직접 state 에 꽂으면 userCharacterId/growthPercent 등이 0 으로 리셋된다.
  /// 성공 직후 GET /api/characters/me 로 전체 정보를 재조회한다.
  Future<bool> renameCharacter(String name) async {
    try {
      await _repository.renameCharacter(name);
      await load();
      return true;
    } catch (e, st) {
      appLogger.e('rename failed', error: e, stackTrace: st);
      return false;
    }
  }

  /// 성장률 100% 도달 시 호출. 동시에 여러 번 호출되는 걸 방지하기 위해
  /// in-flight 플래그로 재진입을 막는다. 진화 후에는 [load] 로 최신 캐릭터
  /// 정보를 다시 당긴다.
  bool _evolving = false;
  Future<bool> evolve(int userCharacterId) async {
    if (_evolving) return false;
    _evolving = true;
    try {
      await _repository.evolveCharacter(userCharacterId);
      await load();
      return true;
    } catch (e, st) {
      appLogger.e('evolve failed', error: e, stackTrace: st);
      return false;
    } finally {
      _evolving = false;
    }
  }

  /// ADULT + canFarewell 상태에서 사용자가 독립을 승인했을 때 호출.
  /// 서버가 다음 알을 자동 배정하므로 [load] 로 새 캐릭터 상태를 당겨온다.
  Future<bool> farewell() async {
    try {
      await _repository.approveFarewell(approved: true);
      await load();
      return true;
    } catch (e, st) {
      appLogger.e('farewell failed', error: e, stackTrace: st);
      return false;
    }
  }
}

final characterViewModelProvider =
    StateNotifierProvider<CharacterViewModel, AsyncValue<Character?>>(
  (ref) => CharacterViewModel(ref.watch(characterRepositoryProvider)),
);