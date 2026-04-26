import 'package:doitdo/core/network/base_repository.dart';
import 'package:doitdo/data/datasources/streak_api.dart';
import 'package:doitdo/domain/entities/streak.dart';
import 'package:doitdo/domain/repositories/streak_repository.dart';

class StreakRepositoryImpl extends BaseRepository implements StreakRepository {
  StreakRepositoryImpl(this._api);

  final StreakApi _api;

  @override
  Future<Streak> getStreak() =>
      safeApiCall(() => _api.getStreak()).then((dto) => dto.toEntity());

  @override
  Future<StreakReward> claimReward() =>
      safeApiCall(() => _api.claimReward()).then((dto) => dto.toEntity());
}
