import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/friend.dart';
import '../../domain/repositories/friend_repository.dart';

class FriendRepositoryImpl implements FriendRepository {
  final SupabaseClient _supabase;
  final Map<String, _CachedProfile> _profileCache = {};

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
      // Определяем ID друга: если текущий пользователь - отправитель, то друг - получатель, и наоборот
      final friendId = data['user_id'] == userId ? data['friend_id'] as String : data['user_id'] as String;
      final friend = await _mapToFriendWithProfile(data, userId, friendId);
      friends.add(friend);
    }
    return friends;
  }

  @override
  Future<List<Friend>> searchUsers(String query) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;

      print('DEBUG: Searching users. Current User ID: $currentUserId, Query: $query');

      final isNumericId = RegExp(r'^\d{10}$').hasMatch(query);

      final queryBuilder = _supabase
          .from('profiles')
          .select('id, nickname, full_name, avatar_url, bio, display_id');

      if (currentUserId != null) {
        queryBuilder.neq('id', currentUserId);
      }

      final response = await queryBuilder
          .or(isNumericId
          ? 'display_id.eq.$query'
          : 'nickname.ilike.%$query%,full_name.ilike.%$query%')
          .limit(20);

      final filteredResponse = response.where((item) => item['id'] != currentUserId).toList();

      print('DEBUG: Total results from DB: ${response.length}, After filter: ${filteredResponse.length}');

      return filteredResponse.map((data) {
        final displayName = data['nickname'] ??
            data['full_name'] ??
            data['display_id']?.toString() ??
            'Unknown';

        return Friend(
          id: data['id'],
          userId: _supabase.auth.currentUser?.id ?? '',
          friendId: data['id'],
          friendNickname: displayName,
          friendFullName: data['full_name'],
          friendBio: data['bio'],
          friendAvatarUrl: data['avatar_url'],
          status: FriendStatus.pending,
          createdAt: DateTime.now(),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error searching users: $e');
      return [];
    }
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
    try {
      await _supabase
          .from('friendships')
          .update({'status': 'accepted'})
          .eq('id', requestId);
    } catch (e) {
      debugPrint('Accept ERROR: $e');
      rethrow;
    }
  }

  void invalidateProfileCache(String userId) {
    _profileCache.remove(userId);
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
      // Для входящих запросов: отправитель - это user_id
      final senderId = data['user_id'] as String;
      final friend = await _mapToFriendWithProfile(data, userId, senderId);
      friends.add(friend);
    }
    return friends;
  }

  @override
  Future<List<Friend>> getSentRequests(String userId) async {
    final response = await _supabase
        .from('friendships')
        .select('*')
        .eq('user_id', userId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    final friends = <Friend>[];
    for (final data in response) {
      // Для исходящих запросов: получатель - это friend_id
      final receiverId = data['friend_id'] as String;
      final friend = await _mapToFriendWithProfile(data, userId, receiverId);
      friends.add(friend);
    }
    return friends;
  }

  @override
  Future<void> cancelSentRequest(String requestId) async {
    await _supabase.from('friendships').delete().eq('id', requestId);
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
        final senderId = item['user_id'] as String;
        final friend = await _mapToFriendWithProfile(item, userId, senderId);
        friends.add(friend);
      }
      return friends;
    });
  }

  @override
  Stream<List<Friend>> sentRequestsStream(String userId) {
    return _supabase
        .from('friendships')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.where((item) =>
    item['user_id'] == userId &&
        item['status'] == 'pending'
    ).toList())
        .asyncMap((data) async {
      final friends = <Friend>[];
      for (final item in data) {
        final receiverId = item['friend_id'] as String;
        final friend = await _mapToFriendWithProfile(item, userId, receiverId);
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
        final friendId = item['user_id'] == userId ? item['friend_id'] as String : item['user_id'] as String;
        final friend = await _mapToFriendWithProfile(item, userId, friendId);
        friends.add(friend);
      }
      return friends;
    });
  }

  Friend _mapToFriend(Map<String, dynamic> data, String currentUserId) {
    final profile = data['profiles'] as Map<String, dynamic>?;
    final friendId = data['friend_id'] as String;
    final isCurrentUserSender = data['user_id'] == currentUserId;

    bool isOnline = false;
    if (profile != null && profile['last_seen_at'] != null) {
      final lastSeen = DateTime.parse(profile['last_seen_at'] as String);
      final now = DateTime.now();
      isOnline = now.difference(lastSeen).inMinutes < 5;
    }

    final displayName = profile?['nickname'] ??
        profile?['full_name'] ??
        profile?['display_id']?.toString() ??
        'Unknown';

    return Friend(
      id: data['id'] as String,
      userId: data['user_id'] as String,
      friendId: friendId,
      friendNickname: displayName,
      friendFullName: profile?['full_name'],
      friendBio: profile?['bio'],
      friendAvatarUrl: profile?['avatar_url'],
      status: _mapStatus(data['status'] as String),
      createdAt: DateTime.parse(data['created_at'] as String),
      updatedAt: data['updated_at'] != null
          ? DateTime.parse(data['updated_at'] as String)
          : null,
      isOnline: isOnline,
    );
  }

  Future<Friend> _mapToFriendWithProfile(Map<String, dynamic> data, String currentUserId, String otherUserId) async {
    final cached = _profileCache[otherUserId];
    final now = DateTime.now();
    Map<String, dynamic>? profile;

    if (cached != null && now.difference(cached.fetchedAt).inMinutes < 5) {
      profile = cached.data;
    } else {
      try {
        final profileData = await _supabase
            .from('profiles')
            .select('nickname, full_name, bio, avatar_url, last_seen_at, display_id')
            .eq('id', otherUserId)
            .single();

        _profileCache[otherUserId] = _CachedProfile(profileData, now);
        profile = profileData;
      } catch (e) {
        debugPrint('Failed to fetch profile for $otherUserId: $e');
        profile = null;
      }
    }

    bool isOnline = false;
    if (profile != null && profile['last_seen_at'] != null) {
      final lastSeen = DateTime.parse(profile['last_seen_at'] as String);
      final now = DateTime.now();
      isOnline = now.difference(lastSeen).inMinutes < 5;
    }

    final displayName = profile?['nickname'] ??
        profile?['full_name'] ??
        profile?['display_id']?.toString() ??
        'Unknown';

    return Friend(
      id: data['id'] as String,
      userId: data['user_id'] as String,
      friendId: otherUserId,
      friendNickname: displayName,
      friendFullName: profile?['full_name'],
      friendBio: profile?['bio'],
      friendAvatarUrl: profile?['avatar_url'],
      status: _mapStatus(data['status'] as String),
      createdAt: DateTime.parse(data['created_at'] as String),
      updatedAt: data['updated_at'] != null
          ? DateTime.parse(data['updated_at'] as String)
          : null,
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

class _CachedProfile {
  final Map<String, dynamic> data;
  final DateTime fetchedAt;
  _CachedProfile(this.data, this.fetchedAt);
}