import 'package:doitdo/domain/entities/character.dart';

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
}