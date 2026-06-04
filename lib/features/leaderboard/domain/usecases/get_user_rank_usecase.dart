import '../repositories/leaderboard_repository.dart';

class GetUserRankUseCase {
  final LeaderboardRepository _repository;

  GetUserRankUseCase(this._repository);

  Future<int> call({
    required String category,
    required String userId,
  }) {
    return _repository.getUserRank(
      category: category,
      userId: userId,
    );
  }
}
