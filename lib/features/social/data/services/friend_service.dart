import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/friend.dart';
import '../../domain/repositories/friend_repository.dart';

class FriendService {
  final FriendRepository _friendRepository;
  final SupabaseClient _supabase;
  final Map<String, Map<String, dynamic>> _profileCache = {};

  FriendService(this._friendRepository, this._supabase);

  /// Send a game invitation to a friend
  Future<void> sendGameInvite(String friendId, Map<String, dynamic> gameConfig) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    await _supabase.from('game_invites').insert({
      'from_user_id': currentUserId,
      'to_user_id': friendId,
      'game_config': gameConfig,
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Accept a game invitation and create the game
  Future<String?> acceptGameInvite(String inviteId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return null;

    // Get the invite details
    final invite = await _supabase
        .from('game_invites')
        .select()
        .eq('id', inviteId)
        .single();

    // Update invite status
    await _supabase
        .from('game_invites')
        .update({'status': 'accepted'})
        .eq('id', inviteId);

    // Create the game
    final gameConfig = invite['game_config'] as Map<String, dynamic>;
    final gameId = await _createGame(invite['from_user_id'], currentUserId, gameConfig);

    return gameId;
  }

  /// Decline a game invitation
  Future<void> declineGameInvite(String inviteId) async {
    await _supabase
        .from('game_invites')
        .update({'status': 'declined'})
        .eq('id', inviteId);
  }

  /// Stream for incoming game invitations
  Stream<List<Map<String, dynamic>>> gameInvitesStream(String userId) {
    return _supabase
        .from('game_invites')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.where((item) =>
            item['to_user_id'] == userId &&
            item['status'] == 'pending'
        ).toList())
        .asyncMap((data) async {
          final invites = <Map<String, dynamic>>[];
          for (final item in data) {
            final invite = await _addProfileToInvite(item);
            invites.add(invite);
          }
          return invites;
        });
  }

  Future<Map<String, dynamic>> _addProfileToInvite(Map<String, dynamic> invite) async {
    final fromUserId = invite['from_user_id'] as String;

    // Try to get profile from cache first
    Map<String, dynamic>? profile = _profileCache[fromUserId];

    // If not in cache, fetch from server
    if (profile == null) {
      try {
        final profileData = await _supabase
            .from('profiles')
            .select('nickname, avatar_url')
            .eq('id', fromUserId)
            .single();
        _profileCache[fromUserId] = profileData;
        profile = profileData;
      } catch (e) {
        debugPrint('Failed to fetch profile for $fromUserId: $e');
        profile = {'nickname': 'Unknown', 'avatar_url': null};
      }
    }

    // Add profile data to invite
    final inviteWithProfile = Map<String, dynamic>.from(invite);
    inviteWithProfile['profiles'] = profile;
    return inviteWithProfile;
  }

  Future<String> _createGame(
    String whiteId,
    String blackId,
    Map<String, dynamic> config,
  ) async {
    final gameData = {
      'white_id': whiteId,
      'black_id': blackId,
      'variant': config['variant'] ?? 'standard',
      'time_control': config['timeControl'] ?? {},
      'status': 'in_progress',
      'fen': config['fen'],
      'created_at': DateTime.now().toIso8601String(),
    };

    final response = await _supabase.from('games').insert(gameData).select();
    return response.first['id'] as String;
  }
}
