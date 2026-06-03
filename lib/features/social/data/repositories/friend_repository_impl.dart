import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/friend.dart';
import '../../domain/repositories/friend_repository.dart';

class FriendRepositoryImpl implements FriendRepository {
  final SupabaseClient _supabase;
  final Map<String, Map<String, dynamic>> _profileCache = {};

  FriendRepositoryImpl(this._supabase);

  @override
  Future<List<Friend>> getFriends(String userId) async {
    final response = await _supabase
        .from('friendships')
        .select('*')
        .or('user_id.eq.$userId,friend_id.eq.$userId')
        .eq('status', 'accepted')
        .order('created_at', ascending: false);

    final friends = <Friend>[];
    for (final data in response) {
      final friend = await _mapToFriendWithProfile(data, userId);
      friends.add(friend);
    }
    return friends;
  }

  @override
  Future<List<Friend>> searchUsers(String query) async {
    final response = await _supabase
        .from('profiles')
        .select('id, nickname, avatar_url')
        .ilike('nickname', '%$query%')
        .limit(20);

    return response.map((data) {
      final isCurrentUser = data['id'] == _supabase.auth.currentUser?.id;
      return Friend(
        id: data['id'],
        userId: _supabase.auth.currentUser?.id ?? '',
        friendId: data['id'],
        friendNickname: data['nickname'] ?? 'Unknown',
        friendAvatarUrl: data['avatar_url'],
        status: isCurrentUser ? FriendStatus.accepted : FriendStatus.pending,
        createdAt: DateTime.now(),
      );
    }).toList();
  }

  @override
  Future<void> sendFriendRequest(String fromUserId, String toUserId) async {
    await _supabase.from('friendships').insert({
      'user_id': fromUserId,
      'friend_id': toUserId,
      'status': 'pending',
    });
  }

  @override
  Future<void> acceptFriendRequest(String requestId) async {
    await _supabase
        .from('friendships')
        .update({'status': 'accepted', 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', requestId);
  }

  @override
  Future<void> declineFriendRequest(String requestId) async {
    await _supabase.from('friendships').delete().eq('id', requestId);
  }

  @override
  Future<void> removeFriend(String friendId) async {
    await _supabase.from('friendships').delete().eq('id', friendId);
  }

  @override
  Future<List<Friend>> getPendingRequests(String userId) async {
    final response = await _supabase
        .from('friendships')
        .select('*')
        .eq('friend_id', userId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    final friends = <Friend>[];
    for (final data in response) {
      final friend = await _mapToFriendWithProfile(data, userId);
      friends.add(friend);
    }
    return friends;
  }

  @override
  Stream<List<Friend>> friendRequestsStream(String userId) {
    return _supabase
        .from('friendships')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.where((item) =>
            item['friend_id'] == userId &&
            item['status'] == 'pending'
        ).toList())
        .asyncMap((data) async {
          final friends = <Friend>[];
          for (final item in data) {
            final friend = await _mapToFriendWithProfile(item, userId);
            friends.add(friend);
          }
          return friends;
        });
  }

  @override
  Stream<List<Friend>> friendsStream(String userId) {
    return _supabase
        .from('friendships')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.where((item) =>
            (item['user_id'] == userId || item['friend_id'] == userId) &&
            item['status'] == 'accepted'
        ).toList())
        .asyncMap((data) async {
          final friends = <Friend>[];
          for (final item in data) {
            final friend = await _mapToFriendWithProfile(item, userId);
            friends.add(friend);
          }
          return friends;
        });
  }

  Friend _mapToFriend(Map<String, dynamic> data, String currentUserId) {
    final profile = data['profiles'] as Map<String, dynamic>?;
    final friendId = data['friend_id'] as String;
    final isCurrentUserSender = data['user_id'] == currentUserId;

    // Extract rating from profile ratings (get standard/blitz rating as default)
    int? rating;
    if (profile != null && profile['ratings'] != null) {
      final ratings = profile['ratings'] as Map<String, dynamic>;
      // Try to get blitz rating first, then standard
      final blitzRating = ratings['blitz']?['rating'];
      final standardRating = ratings['standard']?['rating'];
      rating = (blitzRating ?? standardRating)?.toInt();
    }

    // Determine online status based on last_seen_at
    bool isOnline = false;
    if (profile != null && profile['last_seen_at'] != null) {
      final lastSeen = DateTime.parse(profile['last_seen_at'] as String);
      final now = DateTime.now();
      isOnline = now.difference(lastSeen).inMinutes < 5;
    }

    return Friend(
      id: data['id'] as String,
      userId: data['user_id'] as String,
      friendId: friendId,
      friendNickname: profile?['nickname'] ?? 'Unknown',
      friendAvatarUrl: profile?['avatar_url'],
      status: _mapStatus(data['status'] as String),
      createdAt: DateTime.parse(data['created_at'] as String),
      updatedAt: data['updated_at'] != null
          ? DateTime.parse(data['updated_at'] as String)
          : null,
      rating: rating,
      isOnline: isOnline,
    );
  }

  Future<Friend> _mapToFriendWithProfile(Map<String, dynamic> data, String currentUserId) async {
    final friendId = data['friend_id'] as String;

    // Try to get profile from cache first
    Map<String, dynamic>? profile = _profileCache[friendId];

    // If not in cache or cache is old (> 5 minutes), fetch from server
    if (profile == null) {
      try {
        final profileData = await _supabase
            .from('profiles')
            .select('nickname, avatar_url, last_seen_at, ratings')
            .eq('id', friendId)
            .single();
        _profileCache[friendId] = profileData;
        profile = profileData;
      } catch (e) {
        debugPrint('Failed to fetch profile for $friendId: $e');
        profile = null;
      }
    }

    // Extract rating from profile ratings (get standard/blitz rating as default)
    int? rating;
    if (profile != null && profile['ratings'] != null) {
      final ratings = profile['ratings'] as Map<String, dynamic>;
      final blitzRating = ratings['blitz']?['rating'];
      final standardRating = ratings['standard']?['rating'];
      rating = (blitzRating ?? standardRating)?.toInt();
    }

    // Determine online status based on last_seen_at
    bool isOnline = false;
    if (profile != null && profile['last_seen_at'] != null) {
      final lastSeen = DateTime.parse(profile['last_seen_at'] as String);
      final now = DateTime.now();
      isOnline = now.difference(lastSeen).inMinutes < 5;
    }

    return Friend(
      id: data['id'] as String,
      userId: data['user_id'] as String,
      friendId: friendId,
      friendNickname: profile?['nickname'] ?? 'Unknown',
      friendAvatarUrl: profile?['avatar_url'],
      status: _mapStatus(data['status'] as String),
      createdAt: DateTime.parse(data['created_at'] as String),
      updatedAt: data['updated_at'] != null
          ? DateTime.parse(data['updated_at'] as String)
          : null,
      rating: rating,
      isOnline: isOnline,
    );
  }

  FriendStatus _mapStatus(String status) {
    switch (status) {
      case 'pending':
        return FriendStatus.pending;
      case 'accepted':
        return FriendStatus.accepted;
      case 'declined':
        return FriendStatus.declined;
      default:
        return FriendStatus.pending;
    }
  }
}
