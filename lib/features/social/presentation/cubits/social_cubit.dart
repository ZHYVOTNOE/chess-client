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

  SocialCubit(this._friendRepository, this._friendService)
      : super(SocialState.initial()) {
    _initialize();
  }

  Future<void> _initialize() async {
    final userId = _getCurrentUserId();
    if (userId == null) return;

    // 1. ПЕРВИЧНАЯ ЗАГРУЗКА: чтобы данные подтянулись сразу, не дожидаясь стримов
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

    // 2. Подписка на стримы для синхронизации в реальном времени (если включен Realtime)
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

  Future<void> sendFriendRequest(String friendId, {Friend? knownProfile}) async {
    final userId = _getCurrentUserId();
    if (userId == null) return;

    try {
      await _friendRepository.sendFriendRequest(userId, friendId);

      // Оптимистично добавляем в sentRequests с уже известным профилем
      if (knownProfile != null) {
        final optimistic = knownProfile.copyWith(
          userId: userId,
          status: FriendStatus.pending,
          createdAt: DateTime.now(),
        );
        final updated = [...state.sentRequests, optimistic];
        emit(state.copyWith(sentRequests: updated));
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
        // Мгновенно обновляем: убираем из запросов, добавляем в друзья
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
