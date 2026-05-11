import 'package:doitdo/core/network/base_repository.dart';
import 'package:doitdo/data/datasources/user_api.dart';
import 'package:doitdo/data/models/change_password_request_dto.dart';
import 'package:doitdo/data/models/register_agreements_request_dto.dart';
import 'package:doitdo/data/models/register_birth_date_request_dto.dart';
import 'package:doitdo/data/models/withdraw_request_dto.dart';
import 'package:doitdo/domain/entities/user.dart';
import 'package:doitdo/domain/repositories/user_repository.dart';

/// [UserRepository] 구현체.
///
/// API 호출은 [UserApi] (retrofit) 에 위임하고, 응답 envelope 과 에러 매핑은
/// [BaseRepository.safeApiCall] 에 맡긴다. 이 레이어에서는 **try/catch 금지** —
/// `safeApiCall` 이 DioException 을 NetworkException / ServerException /
/// UnauthorizedException 등으로 이미 변환해주고 있다.
///
/// 추가 메서드는 위와 같은 패턴으로 `safeApiCall(() => _api.xxx())` + DTO→도메인
/// 매핑 한 줄로 끝낸다.
class UserRepositoryImpl extends BaseRepository implements UserRepository {
  UserRepositoryImpl(this._api);

  final UserApi _api;

  @override
  Future<User> getMe() =>
      safeApiCall(() => _api.getMe()).then((dto) => dto.toEntity());

  @override
  Future<int> getBalance() =>
      safeApiCall(() => _api.getBalance()).then((dto) => dto.balance);

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) =>
      safeApiCallNoData(
            () => _api.changePassword(
          ChangePasswordRequestDto(
            currentPassword: currentPassword,
            newPassword: newPassword,
          ),
        ),
      );

  @override
  Future<bool> isEmailAvailable(String email) =>
      safeApiCall(() => _api.checkEmail(email)).then((dto) => dto.available);

  @override
  Future<bool> isUsernameAvailable(String username) =>
      safeApiCall(() => _api.checkUsername(username)).then((dto) => dto.available);

  @override
  Future<void> withdraw({String? currentPassword}) =>
      safeApiCallVoid(
            () => _api.withdraw(
          WithdrawRequestDto(currentPassword: currentPassword),
        ),
      );

  // ── 온보딩 ────────────────────────────────────────────────────

  @override
  Future<User> registerBirthDate(DateTime birthDate) {
    // ISO date (YYYY-MM-DD). DateTime.toIso8601String() 은 시간/타임존까지 포함하므로
    // 직접 date-only 로 포맷한다 — 서버는 LocalDate 로 파싱하기 때문에 시간 부분을
    // 같이 보내면 422 (G00-006) 로 거절될 수 있다.
    final iso =
        '${birthDate.year.toString().padLeft(4, '0')}-${birthDate.month.toString().padLeft(2, '0')}-${birthDate.day.toString().padLeft(2, '0')}';
    return safeApiCall(
          () => _api.registerBirthDate(
        RegisterBirthDateRequestDto(birthDate: iso),
      ),
    ).then((dto) => dto.toEntity());
  }

  @override
  Future<User> registerAgreements({
    required bool termsAgreed,
    required bool privacyAgreed,
    required bool marketingAgreed,
  }) =>
      safeApiCall(
            () => _api.registerAgreements(
          RegisterAgreementsRequestDto(
            termsAgreed: termsAgreed,
            privacyAgreed: privacyAgreed,
            marketingAgreed: marketingAgreed,
          ),
        ),
      ).then((dto) => dto.toEntity());
}