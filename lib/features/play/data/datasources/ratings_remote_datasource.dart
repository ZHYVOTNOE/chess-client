import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/rating_model.dart';

class RatingsRemoteDataSource {
  final SupabaseClient _client;

  RatingsRemoteDataSource(this._client);

  Future<List<RatingModel>> getUserRatings(String userId) async {
    try {
      final response = await _client
          .from('ratings')
          .select('user_id,variant:variant_key,time_control:time_control_type,rating,rd,volatility') // ✅ без запятой
          .eq('user_id', userId);

      return (response as List)
          .map((json) => RatingModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch user ratings: $e');
    }
  }

  /// Fetch a specific rating by variant and time control
  Future<RatingModel?> getRating(
    String userId,
    String variant,
    String timeControl,
  ) async {
    try {
      final response = await _client
          .from('ratings')
          .select()
          .eq('user_id', userId)
          .eq('variant', variant)
          .eq('time_control', timeControl)
          .maybeSingle();

      if (response == null) return null;

      return RatingModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch rating: $e');
    }
  }

  /// Create a new rating entry with default Glicko-2 values
  Future<RatingModel> createRatingEntry({
    required String userId,
    required String variant,
    required String timeControl,
    double initialRating = 1500.0,
    double initialRd = 350.0,
    double initialVolatility = 0.06,
  }) async {
    try {
      final ratingData = {
        'user_id': userId,
        'variant': variant,
        'time_control': timeControl,
        'rating': initialRating,
        'rd': initialRd,
        'volatility': initialVolatility,
        'games_played': 0,
        'wins': 0,
        'losses': 0,
        'draws': 0,
      };

      final response = await _client
          .from('ratings')
          .insert(ratingData)
          .select()
          .single();

      return RatingModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create rating entry: $e');
    }
  }

  /// Update an existing rating entry
  Future<RatingModel> updateRating(RatingModel rating) async {
    try {
      final response = await _client
          .from('ratings')
          .update(rating.toJson())
          .eq('user_id', rating.userId)
          .eq('variant', rating.variant)
          .eq('time_control', rating.timeControl)
          .select()
          .single();

      return RatingModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update rating: $e');
    }
  }

  /// Get rating history for a user
  Future<List<Map<String, dynamic>>> getRatingHistory(String userId) async {
    try {
      final response = await _client
          .from('rating_history')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch rating history: $e');
    }
  }

  Stream<List<RatingModel>> ratingsStream(String userId) {
    return _client
        .from('ratings:user_id=eq.$userId')
        .stream(primaryKey: ['user_id', 'variant_key', 'time_control_type'])
        .map((events) => events
        .map((json) {
      // Применяем те же алиасы
      final mappedJson = {
        'user_id': json['user_id'],
        'variant': json['variant_key'],
        'time_control': json['time_control_type'],
        'rating': json['rating'],
        'rd': json['rd'],
        'volatility': json['volatility'],
      };
      return RatingModel.fromJson(mappedJson);
    })
        .toList());
  }
}
