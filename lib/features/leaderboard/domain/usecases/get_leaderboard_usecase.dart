import '../entities/leaderboard_entry.dart';
import '../repositories/leaderboard_repository.dart';

class GetLeaderboardUseCase {
  final LeaderboardRepository _repository;

  GetLeaderboardUseCase(this._repository);

  Future<List<LeaderboardEntry>> call({
    required String category,
    required String scope,
    int offset = 0,
    int limit = 50,
  }) {
    return _repository.getLeaderboard(
      category: category,
      scope: scope,
      offset: offset,
      limit: limit,
    );
  }
}
