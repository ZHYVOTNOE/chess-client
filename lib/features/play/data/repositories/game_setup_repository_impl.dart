import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/game_setup.dart';
import '../../domain/repositories/game_setup_repository.dart';

class GameSetupRepositoryImpl implements GameSetupRepository {
  final SupabaseClient _client;

  GameSetupRepositoryImpl(this._client);

  @override
  Future<GameSetup?> getGameSetup(String userId) async {
    try {
      final response = await _client
          .from('game_setup')
          .select()
          .eq('user_id', userId)
          .single();

      return GameSetup.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> saveGameSetup(GameSetup gameSetup) async {
    try {
      await _client.from('game_setup').upsert(gameSetup.toMap());
    } catch (e) {
      throw Exception('Failed to save game setup: $e');
    }
  }
}
