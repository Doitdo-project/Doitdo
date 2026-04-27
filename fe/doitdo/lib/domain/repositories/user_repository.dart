import 'package:doitdo/domain/entities/user.dart';

/// 사용자(회원) 도메인 추상화. presentation 레이어(ViewModel)는 이 인터페이스에만
/// 의존하고, 실제 API 호출은 `data/repositories/UserRepositoryImpl` 이 담당한다.
///
/// 네트워크/서버 오류 시 `NetworkException`, `ServerException`,
/// `UnauthorizedException` 등 타입드 예외를 throw 한다. ViewModel 은
/// `AsyncValue.guard` 로 잡아 UI 상태에 그대로 흘린다.
abstract class UserRepository {
  /// 현재 로그인된 사용자의 최신 정보 조회. 토큰이 유효하지 않으면
  /// `UnauthorizedException` 이 떨어진다.
  Future<User> getMe();

  /// 비밀번호 변경.
  /// - 현재 비밀번호가 틀리면 `ServerException` (BE 메시지 포함) 발생.
  /// - 새 비밀번호 길이/복잡도 정책 위반도 서버에서 검증 후 `ServerException`.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// 가입 가능한 이메일인지 확인.
  /// - `true`: 사용 가능 (미등록)
  /// - `false`: 이미 등록된 이메일
  Future<bool> isEmailAvailable(String email);

  /// 가입 가능한 닉네임(username) 인지 확인.
  /// - `true`: 사용 가능 (미등록)
  /// - `false`: 이미 사용 중
  Future<bool> isUsernameAvailable(String username);

  /// 회원탈퇴 (소프트 삭제). 성공 시 서버에서 isDeleted=true, email/username
  /// 익명화 처리. 호출자는 성공 후 토큰 정리(`AuthRepository.signOut`) 와
  /// Welcome 화면 라우팅을 별도로 수행해야 한다.
  ///
  /// [currentPassword] 는 일반(이메일+비번) 계정에서만 필수. OAuth 계정은 null.
  /// 일반 계정인데 비번을 안 보내거나 틀리면 `ServerException` (BE 메시지 포함).
  Future<void> withdraw({String? currentPassword});
}
