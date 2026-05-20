import 'package:doitdo/domain/entities/character.dart';
import 'package:doitdo/domain/entities/evolution.dart';
import 'package:doitdo/presentation/models/collection_entry.dart';

/// 현재 사용자의 다마고치 캐릭터 도메인 추상화.
///
/// [getMyCharacter] 는 아직 캐릭터가 없는 사용자에 대해 서버가 4xx 로 응답한다고
/// 가정하고, 그 경우 [ServerException] (또는 [UnauthorizedException] 등) 을 그대로
/// throw 한다. "없음"을 null 로 표현하는 래퍼는 ViewModel 쪽에서 처리한다.
abstract class CharacterRepository {
  /// 회원가입 직후 알 1회 수령. 이미 수령한 사용자는 서버가 실패 응답을 낼 수 있다.
  Future<Character> receiveEgg();

  /// 현재 캐릭터 조회. 아직 수령 전이면 서버 에러로 내려오므로 ViewModel 은
  /// 이 예외를 "미수령" 상태로 해석하면 된다.
  Future<Character> getMyCharacter();

  /// 알을 부화시킨다. 홈에서 알을 10회 두드린 직후 호출.
  /// 성공 시 부화된 상태의 캐릭터가 반환된다.
  Future<Character> hatchEgg();

  /// 이름짓기 화면에서 제출. 성공 시 이름이 반영된 캐릭터 반환.
  Future<Character> renameCharacter(String name);

  /// 성장률 100% 달성 시 호출. 응답으로 진화 연출에 필요한 [Evolution] (전/후 단계,
  /// animation gif, 새 캐릭터 이미지) 을 돌려준다 — 호출자는 이걸로 overlay 연출을
  /// 띄우고, 갱신된 캐릭터 본체(이름/장착 아이템 등) 는 [getMyCharacter] 로 따로
  /// 당겨 동기화한다.
  Future<Evolution> evolveCharacter(int userCharacterId);

  /// 캐릭터 상호작용 액션. 홈 화면 캐릭터 탭에서 IDLE 등을 호출한다.
  ///
  /// 반환:
  ///   - [url] 동작 gif URL. 호출자는 이걸 캐릭터 썸네일 자리에 잠시 swap 해
  ///     동작을 재생한다. 빈 문자열이면 swap 없이 정적 썸네일 유지.
  ///   - [earnedAmount] 이번 탭으로 지급된 코인량. 0 이면 일일 한도 초과 등으로
  ///     보상 미지급 — 호출자는 floating "+N" 시각화를 띄우지 않는다.
  Future<({String url, int earnedAmount})> triggerAction(
    CharacterAction action,
  );

  /// 서버 actionType 문자열을 그대로 호출한다.
  ///
  /// FE enum 업데이트보다 BE actionType 이 먼저 배포되는 경우에도 호출 경로를
  /// 유지하기 위한 escape hatch 이다. 호출자는 빈 문자열만 피하면 된다.
  Future<({String url, int earnedAmount})> triggerActionType(String actionType);

  /// 도감 목록. 미해금 항목은 species/thumbnailUrl 은 들어와도 UI 에서 가린다.
  Future<List<CollectionEntry>> getEncyclopedia();

  /// 도감 상세. [species] 는 BE 의 enum 값 (예: "CAT").
  Future<EncyclopediaDetail> getEncyclopediaDetail(String species);

  /// 독립 승인. [approved] false 로 보내면 서버가 알 배정 없이 현 상태 유지.
  /// 캐릭터 상태 반영은 호출자가 [getMyCharacter] 재조회로 맞춘다.
  Future<void> approveFarewell({required bool approved});
}
