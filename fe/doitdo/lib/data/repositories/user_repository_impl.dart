import 'package:doitdo/core/network/base_repository.dart';
import 'package:doitdo/data/datasources/user_api.dart';
import 'package:doitdo/data/models/change_password_request_dto.dart';
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
}
