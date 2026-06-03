import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class GameService {
  final SupabaseClient _client;

  GameService(this._client);

  /// Calls Supabase RPC find_match to enter matchmaking queue
  Future<String?> findMatch({
    required String variant,
    required String timeControl,
    required String ratingRange,
  }) async {
    try {
      final response = await _client.rpc('find_match', params: {
        'p_variant': variant,
        'p_time_control': timeControl,
        'p_rating_range': ratingRange,
      });

      return response as String?;
    } catch (e) {
      throw Exception('Failed to find match: $e');
    }
  }

  /// Updates games.fen and inserts into moves table in one transaction
  Future<void> makeMove({
    required String gameId,
    required String move,
    required String fen,
    required String userId,
  }) async {
    try {
      await _client.rpc('make_move', params: {
        'p_game_id': gameId,
        'p_move': move,
        'p_fen': fen,
        'p_user_id': userId,
      });
    } catch (e) {
      throw Exception('Failed to make move: $e');
    }
  }

  /// Subscribes to games table via Supabase Realtime for opponent moves
  Stream<Map<String, dynamic>> syncStream(String gameId) {
    return _client
        .from('games')
        .stream(primaryKey: ['id'])
        .eq('id', gameId)
        .map((event) => event.first);
  }

  /// Updates draw_offered_by column in games table
  Future<void> offerDraw({
    required String gameId,
    required String userId,
  }) async {
    try {
      await _client.from('games').update({
        'draw_offered_by': userId,
      }).eq('id', gameId);
    } catch (e) {
      throw Exception('Failed to offer draw: $e');
    }
  }

  /// Updates game status to resigned
  Future<void> resign({
    required String gameId,
    required String userId,
  }) async {
    try {
      await _client.from('games').update({
        'status': 'resigned',
        'winner': userId == _client.auth.currentUser?.id ? 'opponent' : userId,
      }).eq('id', gameId);
    } catch (e) {
      throw Exception('Failed to resign: $e');
    }
  }

  /// Removes user from matchmaking_queue
  Future<void> leaveQueue() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      await _client.from('matchmaking_queue').delete().eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to leave queue: $e');
    }
  }

  /// Subscribes to matchmaking_queue to detect when match is found
  Stream<Map<String, dynamic>> matchmakingQueueStream(String userId) {
    return _client
        .from('matchmaking_queue')
        .stream(primaryKey: ['user_id'])
        .eq('user_id', userId)
        .map((event) => event.first);
  }

  /// Gets game data by ID
  Future<Map<String, dynamic>?> getGame(String gameId) async {
    try {
      final response = await _client
          .from('games')
          .select()
          .eq('id', gameId)
          .single();
      return response;
    } catch (e) {
      throw Exception('Failed to get game: $e');
    }
  }

  /// Gets moves for a game
  Future<List<Map<String, dynamic>>> getMoves(String gameId) async {
    try {
      final response = await _client
          .from('moves')
          .select()
          .eq('game_id', gameId)
          .order('move_number', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get moves: $e');
    }
  }

  /// Calls calculate_rating_after_game RPC when online game ends
  Future<void> calculateRatingAfterGame(String gameId) async {
    try {
      await _client.rpc('calculate_rating_after_game', params: {
        'p_game_id': gameId,
      });
    } catch (e) {
      throw Exception('Failed to calculate rating: $e');
    }
  }
}
