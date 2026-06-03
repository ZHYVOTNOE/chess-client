abstract class MatchmakingRepository {
  /// Enter matchmaking queue with specified parameters
  Future<String?> enterQueue({
    required String variant,
    required String timeControl,
    required String ratingRange,
  });

  /// Leave matchmaking queue
  Future<void> leaveQueue();

  /// Subscribe to matchmaking queue to detect when match is found
  Stream<Map<String, dynamic>> queueStream(String userId);
}
