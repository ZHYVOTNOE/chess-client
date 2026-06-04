import '../entities/leaderboard_entry.dart';

abstract class LeaderboardRepository {
  /// Fetch leaderboard entries with pagination
  Future<List<LeaderboardEntry>> getLeaderboard({
    required String category,
    required String scope,
    int offset = 0,
    int limit = 50,
  });

  /// Get current user's rank for a specific category
  Future<int> getUserRank({
    required String category,
    required String userId,
  });

  /// Get current user's country code
  Future<String?> getCurrentUserCountryCode(String userId);

  /// Get current user's leaderboard entry
  Future<LeaderboardEntry?> getCurrentUserEntry({
    required String category,
    required String userId,
  });
}
