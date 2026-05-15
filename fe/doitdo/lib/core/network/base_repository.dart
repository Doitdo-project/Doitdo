import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:doitdo/core/errors/exceptions.dart';
import 'package:doitdo/core/network/api_response.dart';
import 'package:doitdo/core/network/dio_error_mapper.dart';
import 'package:doitdo/core/utils/app_logger.dart';

abstract class BaseRepository {
  const BaseRepository();

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
          code: response.code,
        );
      }
      final data = response.data;
      if (data == null) {
        throw ServerException(
          '필요한 정보를 가져오지 못했어요. 잠시 후 다시 시도해 주세요.',
          statusCode: response.status,
          code: response.code,
        );
      }
      return data;
    } on DioException catch (e) {
      throw mapDioException(e);
    } on Exception {
      rethrow;
    } catch (e, st) {
      appLogger.e(
        'safeApiCall unexpected ${debugLabel ?? ''}',
        error: e,
        stackTrace: st,
      );
      throw const UnknownException('일시적인 오류가 발생했어요. 잠시 후 다시 시도해 주세요.');
    }
  }

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
      throw const UnknownException('일시적인 오류가 발생했어요. 잠시 후 다시 시도해 주세요.');
    }
  }

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
          code: response.code,
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
      throw const UnknownException('일시적인 오류가 발생했어요. 잠시 후 다시 시도해 주세요.');
    }
  }
}
