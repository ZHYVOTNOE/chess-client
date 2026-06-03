import '../../data/services/game_service.dart';
import '../../domain/repositories/matchmaking_repository.dart';

class MatchmakingRepositoryImpl implements MatchmakingRepository {
  final GameService _gameService;

  MatchmakingRepositoryImpl(this._gameService);

  @override
  Future<String?> enterQueue({
    required String variant,
    required String timeControl,
    required String ratingRange,
  }) async {
    return await _gameService.findMatch(
      variant: variant,
      timeControl: timeControl,
      ratingRange: ratingRange,
    );
  }

  @override
  Future<void> leaveQueue() async {
    await _gameService.leaveQueue();
  }

  @override
  Stream<Map<String, dynamic>> queueStream(String userId) {
    return _gameService.matchmakingQueueStream(userId);
  }
}
