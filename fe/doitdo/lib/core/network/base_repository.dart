import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:doitdo/core/errors/exceptions.dart';
import 'package:doitdo/core/network/api_response.dart';
import 'package:doitdo/core/network/dio_error_mapper.dart';
import 'package:doitdo/core/utils/app_logger.dart';

/// 모든 `RepositoryImpl` 의 공통 부모.
///
/// Retrofit 이 반환하는 `Future<ApiResponse<T>>` 를 한 곳에서 처리하도록 해서
/// repository 구현체마다 try/catch 가 중복되는 걸 방지한다.
///
/// ### 처리 순서
/// 1. [block] 실행 중 [DioException] 이 던져지면 → [mapDioException] 으로
///    프로젝트 타입드 예외(NetworkException / ServerException / ...)로 변환
/// 2. envelope 에서 `status` 가 2xx 가 아니면 → [ServerException] 으로 throw
/// 3. envelope 에서 `data == null` 이면 → [ServerException] 으로 throw
///    (데이터 없는 엔드포인트는 [safeApiCallNoData] 사용)
/// 4. 정상 → `T` 를 그대로 반환
///
/// ViewModel 레이어는 `AsyncNotifier` / `AsyncValue.guard` 로 이 예외들을 잡아
/// UI 상태(loading/data/error)에 그대로 바인딩한다.
///
/// ### 사용 예
/// ```dart
/// class UserRepositoryImpl extends BaseRepository implements UserRepository {
///   UserRepositoryImpl(this._api);
///   final UserApi _api;
///
///   @override
///   Future<User> getUser(int id) =>
///       safeApiCall(() => _api.getUser(id)).then((dto) => dto.toEntity());
///
///   @override
///   Future<void> deleteUser(int id) =>
///       safeApiCallNoData(() => _api.deleteUser(id));
/// }
/// ```
abstract class BaseRepository {
  const BaseRepository();

  /// 데이터를 반환하는 엔드포인트용.
  @protected
  Future<T> safeApiCall<T>(
    Future<ApiResponse<T>> Function() block, {
    String? debugLabel,
  }) async {
    try {
      final response = await block();
      if (!response.isSuccess) {
        throw ServerException(
          response.message,
          statusCode: response.status,
        );
      }
      final data = response.data;
      if (data == null) {
        throw ServerException(
          '응답에 data 가 포함되지 않았습니다.',
          statusCode: response.status,
        );
      }
      return data;
    } on DioException catch (e) {
      throw mapDioException(e);
    } on Exception {
      // 이미 타입드 예외(ServerException 등)는 그대로 올려보낸다.
      rethrow;
    } catch (e, st) {
      appLogger.e(
        'safeApiCall unexpected ${debugLabel ?? ''}',
        error: e,
        stackTrace: st,
      );
      throw UnknownException(e.toString());
    }
  }

  /// 204 No Content 처럼 body 자체가 없는 엔드포인트용.
  ///
  /// Retrofit 쪽에서 `Future<void>` 로 선언하면 retrofit_generator 가
  /// body 파싱 코드를 아예 생성하지 않아서 null body 로 인한 런타임 에러가 없다.
  @protected
  Future<void> safeApiCallVoid(
    Future<void> Function() block, {
    String? debugLabel,
  }) async {
    try {
      await block();
    } on DioException catch (e) {
      throw mapDioException(e);
    } on Exception {
      rethrow;
    } catch (e, st) {
      appLogger.e(
        'safeApiCallVoid unexpected ${debugLabel ?? ''}',
        error: e,
        stackTrace: st,
      );
      throw UnknownException(e.toString());
    }
  }

  /// 본문 없이 성공/실패만 신경 쓰면 되는 엔드포인트용 (e.g. DELETE, 로그아웃).
  ///
  /// Retrofit 쪽은 `Future<ApiResponse<ApiVoid>>` 로 선언한다.
  /// `Object?` 를 사용하면 retrofit_generator 가 존재하지 않는
  /// `Object.fromJson` 을 생성해 컴파일 에러가 발생하기 때문.
  @protected
  Future<void> safeApiCallNoData<T>(
    Future<ApiResponse<T>> Function() block, {
    String? debugLabel,
  }) async {
    try {
      final response = await block();
      if (!response.isSuccess) {
        throw ServerException(
          response.message,
          statusCode: response.status,
        );
      }
    } on DioException catch (e) {
      throw mapDioException(e);
    } on Exception {
      rethrow;
    } catch (e, st) {
      appLogger.e(
        'safeApiCallNoData unexpected ${debugLabel ?? ''}',
        error: e,
        stackTrace: st,
      );
      throw UnknownException(e.toString());
    }
  }
}