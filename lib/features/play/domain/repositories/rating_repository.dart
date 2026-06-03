import '../entities/rating.dart';

abstract class RatingRepository {
  /// Fetch all ratings for a user
  Future<List<Rating>> getUserRatings(String userId);

  /// Fetch a specific rating by variant and time control
  Future<Rating?> getRating(
    String userId,
    String variant,
    String timeControl,
  );

  /// Create a new rating entry with default Glicko-2 values
  Future<Rating> createRatingEntry({
    required String userId,
    required String variant,
    required String timeControl,
    double initialRating,
    double initialRd,
    double initialVolatility,
  });

  /// Update an existing rating entry
  Future<Rating> updateRating(Rating rating);
}
