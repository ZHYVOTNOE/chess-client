import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GameService {
  final SupabaseClient _client;
  GameService(this._client);

  // ─── MATCHMAKING ─────────────────────────────────────────────────────
  Future<String?> findMatch({
    required String variant,
    required String timeControl,
    required String ratingRange,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      int range = 200;
      if (ratingRange != 'any' && ratingRange.isNotEmpty) {
        range = int.tryParse(ratingRange.replaceAll('±', '')) ?? 200;
      }

      final response = await _client.rpc('find_match', params: {
        'p_user_id': userId,
        'p_variant_key': variant,
        'p_time_control_type': timeControl,
        'p_min_rating': 1500 - range,
        'p_max_rating': 1500 + range,
      });

      if (response == null) return null;
      if (response is String) return response;
      if (response is Map<String, dynamic>) {
        return (response['match_found'] == true) ? response['game_id'] as String? : null;
      }
      return null;
    } catch (e) {
      debugPrint('❌ [GameService] findMatch error: $e');
      rethrow;
    }
  }

  Future<void> leaveQueue() async {
    final userId = _client.auth.currentUser?.id;
    if (userId != null) {
      await _client.from('matchmaking_queue').delete().eq('user_id', userId);
    }
  }

  Stream<Map<String, dynamic>> queueStream(String userId) {
    return _client
        .from('matchmaking_queue')
        .stream(primaryKey: ['user_id'])
        .eq('user_id', userId)
        .asyncExpand((events) async* {
      for (final e in events) {
        if (e['game_id'] != null) yield e;
      }
    });
  }

  // ─── ONLINE GAME SYNC ────────────────────────────────────────────────

  /// Отправляет ход на сервер. Параметры точно совпадают с SQL make_move
  Future<void> makeMove({
    required String gameId,
    required String uci,
    required String fen,
    required String userId,
  }) async {
    try {
      debugPrint('📤 [GameService] makeMove: game=$gameId uci=$uci');
      await _client.rpc('make_move', params: {
        'p_game_id': gameId,
        'p_user_id': userId,
        'p_move': uci,
        'p_fen': fen,
      });
      debugPrint('✅ [GameService] makeMove OK');
    } catch (e) {
      debugPrint('❌ [GameService] makeMove error: $e');
      rethrow;
    }
  }

  /// Слушает новые ходы в таблице moves
  Stream<Map<String, dynamic>> movesStream(String gameId) {
    return _client
        .from('moves')
        .stream(primaryKey: ['id'])
        .eq('game_id', gameId)
        .map((rows) {
      if (rows.isEmpty) return <String, dynamic>{};
      rows.sort((a, b) => (a['move_number'] as int).compareTo(b['move_number'] as int));
      return rows.last;
    });
  }

  /// Слушает изменения в таблице games (статус, таймеры, winner)
  Stream<Map<String, dynamic>> gamesStream(String gameId) {
    return _client
        .from('games')
        .stream(primaryKey: ['id'])
        .eq('id', gameId)
        .map((rows) => rows.isEmpty ? <String, dynamic>{} : rows.first);
  }

  Future<Map<String, dynamic>?> getGame(String gameId) async {
    try {
      return await _client.from('games').select().eq('id', gameId).single();
    } catch (e) {
      debugPrint('❌ [GameService] getGame error: $e');
      return null;
    }
  }

  Future<void> resign({required String gameId, required String userId}) async {
    await _client.from('games').update({
      'status': 'resigned',
      'winner': userId == _client.auth.currentUser?.id ? 'opponent' : userId,
    }).eq('id', gameId);
  }

  Future<void> offerDraw({required String gameId, required String userId}) async {
    try {
      await _client.from('games').update({
        'draw_offered_by': userId,
      }).eq('id', gameId);
    } catch (e) {
      debugPrint('❌ [GameService] offerDraw error: $e');
      rethrow;
    }
  }
}