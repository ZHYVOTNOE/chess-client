import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/services/friend_service.dart';
import '../../domain/entities/friend.dart';
import '../../domain/repositories/friend_repository.dart';

part 'social_state.dart';

class SocialCubit extends Cubit<SocialState> {
  final FriendRepository _friendRepository;
  final FriendService _friendService;
  final _supabase = Supabase.instance.client;

  SocialCubit(this._friendRepository, this._friendService)
      : super(SocialState.initial()) {
    _initialize();
  }

  Future<void> _initialize() async {
    final userId = _getCurrentUserId();
    if (userId == null) return;

    // Загружаем роль текущего пользователя
    await _loadCurrentUserRole(userId);

    try {
      final friends = await _friendRepository.getFriends(userId);
      final requests = await _friendRepository.getPendingRequests(userId);
      final sentRequests = await _friendRepository.getSentRequests(userId);
      emit(state.copyWith(
        friends: friends,
        friendRequests: requests,
        sentRequests: sentRequests,
        pendingRequestsCount: requests.length,
      ));
    } catch (e) {
      debugPrint('Error initializing social data: $e');
    }

    _friendRepository.friendsStream(userId).listen((friends) {
      emit(state.copyWith(friends: friends));
    });

    _friendRepository.friendRequestsStream(userId).listen((requests) {
      emit(state.copyWith(
        friendRequests: requests,
        pendingRequestsCount: requests.length,
      ));
    });

    _friendRepository.sentRequestsStream(userId).listen((requests) {
      emit(state.copyWith(sentRequests: requests));
    });

    _friendService.gameInvitesStream(userId).listen((invites) {
      emit(state.copyWith(gameInvites: invites));
    });
  }

  Future<void> _loadCurrentUserRole(String userId) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .single();
      emit(state.copyWith(currentUserRole: data['role'] ?? 'user'));
    } catch (e) {
      debugPrint('Error loading user role: $e');
    }
  }

  String? _getCurrentUserId() {
    return _supabase.auth.currentUser?.id;
  }

  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      emit(state.copyWith(searchResults: [], bannedUserIds: {}));
      return;
    }

    emit(state.copyWith(isSearching: true));

    try {
      final results = await _friendRepository.searchUsers(query);

      // Если текущий пользователь — админ, подгружаем статусы банов
      Set<String> bannedIds = {};
      if (state.isAdmin && results.isNotEmpty) {
        final ids = results.map((u) => u.friendId).toList();
        final banned = await _supabase
            .from('profiles')
            .select('id, is_banned, banned_until')
            .inFilter('id', ids);

        final now = DateTime.now();
        bannedIds = (banned as List)
            .where((p) {
          if (p['is_banned'] != true) return false;
          final until = p['banned_until'];
          if (until == null) return true; // перманентный
          return DateTime.parse(until).isAfter(now);
        })
            .map<String>((p) => p['id'] as String)
            .toSet();
      }

      emit(state.copyWith(
        searchResults: results,
        bannedUserIds: bannedIds,
        isSearching: false,
      ));
    } catch (e) {
      emit(state.copyWith(isSearching: false, error: e.toString()));
    }
  }

  /// Забанить пользователя.
  /// [bannedUntil] == null означает перманентный бан.
  Future<void> banUser({
    required String userId,
    required String reason,
    DateTime? bannedUntil,
  }) async {
    final adminId = _getCurrentUserId();
    if (adminId == null) return;

    try {
      await _supabase.from('profiles').update({
        'is_banned': true,
        'ban_reason': reason,
        'banned_until': bannedUntil?.toIso8601String(),
        'banned_by': adminId,
      }).eq('id', userId);

      // Обновляем локальное состояние оптимистично
      final updated = {...state.bannedUserIds, userId};
      emit(state.copyWith(bannedUserIds: updated));
    } catch (e) {
      emit(state.copyWith(error: 'Ошибка бана: ${e.toString()}'));
    }
  }

  Future<void> unbanUser(String userId) async {
    try {
      await _supabase.from('profiles').update({
        'is_banned': false,
        'ban_reason': null,
        'banned_until': null,
        'banned_by': null,
      }).eq('id', userId);

      // Убираем из локального состояния
      final updated = {...state.bannedUserIds}..remove(userId);
      emit(state.copyWith(bannedUserIds: updated));
    } catch (e) {
      emit(state.copyWith(error: 'Ошибка разбана: ${e.toString()}'));
    }
  }

  // --- Остальные методы без изменений ---

  Future<void> sendFriendRequest(String friendId, {Friend? knownProfile}) async {
    final userId = _getCurrentUserId();
    if (userId == null) return;
    try {
      await _friendRepository.sendFriendRequest(userId, friendId);
      if (knownProfile != null) {
        final optimistic = knownProfile.copyWith(
          userId: userId,
          status: FriendStatus.pending,
          createdAt: DateTime.now(),
        );
        emit(state.copyWith(sentRequests: [...state.sentRequests, optimistic]));
      } else {
        final sentRequests = await _friendRepository.getSentRequests(userId);
        emit(state.copyWith(sentRequests: sentRequests));
      }
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> acceptFriendRequest(String requestId) async {
    try {
      await _friendRepository.acceptFriendRequest(requestId);
      final userId = _getCurrentUserId();
      if (userId != null) {
        final friends = await _friendRepository.getFriends(userId);
        final requests = await _friendRepository.getPendingRequests(userId);
        emit(state.copyWith(
          friends: friends,
          friendRequests: requests,
          pendingRequestsCount: requests.length,
        ));
      }
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> declineFriendRequest(String requestId) async {
    try {
      await _friendRepository.declineFriendRequest(requestId);
      final userId = _getCurrentUserId();
      if (userId != null) {
        final requests = await _friendRepository.getPendingRequests(userId);
        emit(state.copyWith(
          friendRequests: requests,
          pendingRequestsCount: requests.length,
        ));
      }
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> cancelSentRequest(String requestId) async {
    try {
      await _friendRepository.cancelSentRequest(requestId);
      final userId = _getCurrentUserId();
      if (userId != null) {
        final sentRequests = await _friendRepository.getSentRequests(userId);
        emit(state.copyWith(sentRequests: sentRequests));
      }
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> removeFriend(String friendId) async {
    try {
      await _friendRepository.removeFriend(friendId);
      final userId = _getCurrentUserId();
      if (userId != null) {
        final friends = await _friendRepository.getFriends(userId);
        emit(state.copyWith(friends: friends));
      }
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> sendGameInvite(String friendId, Map<String, dynamic> gameConfig) async {
    try {
      await _friendService.sendGameInvite(friendId, gameConfig);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<String?> acceptGameInvite(String inviteId) async {
    try {
      return await _friendService.acceptGameInvite(inviteId);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
      return null;
    }
  }

  Future<void> declineGameInvite(String inviteId) async {
    try {
      await _friendService.declineGameInvite(inviteId);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  void clearError() {
    emit(state.copyWith(error: null));
  }
}