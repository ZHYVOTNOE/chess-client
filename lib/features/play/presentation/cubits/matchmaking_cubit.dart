import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/matchmaking_repository.dart';

// States
class MatchmakingState {
  final bool isSearching;
  final String? gameId;
  final String? error;

  const MatchmakingState({
    this.isSearching = false,
    this.gameId,
    this.error,
  });

  MatchmakingState copyWith({
    bool? isSearching,
    String? gameId,
    String? error,
  }) {
    return MatchmakingState(
      isSearching: isSearching ?? this.isSearching,
      gameId: gameId ?? this.gameId,
      error: error ?? this.error,
    );
  }
}

class MatchmakingCubit extends Cubit<MatchmakingState> {
  final MatchmakingRepository _matchmakingRepository;
  StreamSubscription? _queueSubscription;

  MatchmakingCubit(this._matchmakingRepository) : super(const MatchmakingState());

  Future<void> startSearch({
    required String variant,
    required String timeControl,
    required String ratingRange,
  }) async {
    emit(state.copyWith(isSearching: true, error: null));

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        emit(state.copyWith(
          isSearching: false,
          error: 'User not authenticated',
        ));
        return;
      }

      // Enter matchmaking queue
      final gameId = await _matchmakingRepository.enterQueue(
        variant: variant,
        timeControl: timeControl,
        ratingRange: ratingRange,
      );

      if (gameId != null) {
        // Match found immediately
        emit(state.copyWith(isSearching: false, gameId: gameId));
      } else {
        // Subscribe to queue to wait for match
        _queueSubscription = _matchmakingRepository.queueStream(userId).listen(
          (queueData) {
            final matchGameId = queueData['game_id'] as String?;
            if (matchGameId != null) {
              emit(state.copyWith(isSearching: false, gameId: matchGameId));
              _queueSubscription?.cancel();
            }
          },
          onError: (error) {
            emit(state.copyWith(
              isSearching: false,
              error: error.toString(),
            ));
          },
        );
      }
    } catch (e) {
      emit(state.copyWith(
        isSearching: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> cancelSearch() async {
    try {
      await _matchmakingRepository.leaveQueue();
      _queueSubscription?.cancel();
      emit(state.copyWith(isSearching: false, gameId: null, error: null));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _queueSubscription?.cancel();
    return super.close();
  }
}
