import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/core/errors/exceptions.dart';
import 'package:doitdo/core/utils/app_logger.dart';
import 'package:doitdo/domain/entities/character.dart';
import 'package:doitdo/domain/entities/evolution.dart';
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

  // 진행 중인 API 요청을 추적하기 위한 변수
  Future<void>? _loadInFlight;

  /// 외부에서 호출하는 안전한 load 메서드
  Future<void> load() {
    // 이미 진행 중인 요청이 있다면 해당 Future를 그대로 반환하여 중복 호출 방지
    if (_loadInFlight != null) return _loadInFlight!;

    _loadInFlight = _doLoad().whenComplete(() {
      // 요청이 완료(성공/실패 무관)되면 in-flight 상태 초기화
      _loadInFlight = null;
    });

    return _loadInFlight!;
  }

  /// 실제 API 통신 및 상태 갱신을 담당하는 내부 메서드
  Future<void> _doLoad() async {
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
  ///
  /// splash 단계에서 prime 으로 이미 캐릭터 데이터가 있는 경우, 또 GET 을 날리지
  /// 않는다 — 페이지 진입 시 중복 네트워크 왕복을 막아 즉시 그려지게 한다.
  /// 진화/부화 등 명시적 갱신은 [load] / [refresh] 를 직접 호출하면 된다.
  Future<void> ensureCharacter() async {
    final cached = state.valueOrNull;
    if (cached != null) {
      return; // 이미 prime 된 상태 — 추가 fetch 생략.
    }
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
  /// in-flight 플래그로 재진입을 막는다.
  ///
  /// 응답으로 받은 [Evolution] 을 그대로 반환만 하고 home state(=현재 캐릭터)
  /// 갱신은 일부러 하지 않는다. 호출자가 진화 연출 overlay 를 띄우는 동안
  /// home 뒤편으로 옛 캐릭터가 비쳐야 자연스럽기 때문(여기서 [refresh] 를
  /// 돌리면 overlay 가 dim 으로 덮어도 새 캐릭터가 슬쩍 비친다).
  /// overlay 가 닫힌 뒤 호출자가 [refresh] 를 직접 돌려 home 을 새 캐릭터로 동기화한다.
  ///
  /// 실패 시 null 을 반환하고 이전 캐릭터 상태를 유지한다.
  bool _evolving = false;
  Future<Evolution?> evolve(int userCharacterId) async {
    if (_evolving) return null;
    _evolving = true;
    try {
      return await _repository.evolveCharacter(userCharacterId);
    } catch (e, st) {
      appLogger.e('evolve failed', error: e, stackTrace: st);
      return null;
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