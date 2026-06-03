import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/services/friend_service.dart';
import '../../domain/entities/friend.dart';
import '../../domain/repositories/friend_repository.dart';

part 'social_state.dart';

class SocialCubit extends Cubit<SocialState> {
  final FriendRepository _friendRepository;
  final FriendService _friendService;

  SocialCubit(this._friendRepository, this._friendService)
      : super(SocialState.initial()) {
    _initialize();
  }

  Future<void> _initialize() async {
    final userId = _getCurrentUserId();
    if (userId == null) return;

    // Listen to friends stream
    _friendRepository.friendsStream(userId).listen((friends) {
      emit(state.copyWith(friends: friends));
    });

    // Listen to friend requests stream
    _friendRepository.friendRequestsStream(userId).listen((requests) {
      emit(state.copyWith(
        friendRequests: requests,
        pendingRequestsCount: requests.length,
      ));
    });

    // Listen to sent requests stream
    _friendRepository.sentRequestsStream(userId).listen((requests) {
      emit(state.copyWith(sentRequests: requests));
    });

    // Listen to game invites stream
    _friendService.gameInvitesStream(userId).listen((invites) {
      emit(state.copyWith(gameInvites: invites));
    });
  }

  String? _getCurrentUserId() {
    return Supabase.instance.client.auth.currentUser?.id;
  }

  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      emit(state.copyWith(searchResults: []));
      return;
    }

    emit(state.copyWith(isSearching: true));

    try {
      final results = await _friendRepository.searchUsers(query);
      emit(state.copyWith(searchResults: results, isSearching: false));
    } catch (e) {
      emit(state.copyWith(isSearching: false, error: e.toString()));
    }
  }

  Future<void> sendFriendRequest(String friendId) async {
    final userId = _getCurrentUserId();
    if (userId == null) return;

    try {
      await _friendRepository.sendFriendRequest(userId, friendId);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> acceptFriendRequest(String requestId) async {
    try {
      await _friendRepository.acceptFriendRequest(requestId);
      // Force refresh to ensure UI updates immediately
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
      // Force refresh to ensure UI updates immediately
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
      // Force refresh to ensure UI updates immediately
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
