import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/websocket_service.dart';

class MatchmakingState {
  final bool isConnected;
  final bool isAuthenticated;
  final bool isSearching;
  final String? gameId;
  final String? whiteId;
  final String? blackId;
  final String? yourColor;
  final String? initialFen;
  final String? error;

  const MatchmakingState({
    this.isConnected = false,
    this.isAuthenticated = false,
    this.isSearching = false,
    this.gameId,
    this.whiteId,
    this.blackId,
    this.yourColor,
    this.initialFen,
    this.error,
  });

  MatchmakingState copyWith({
    bool? isConnected,
    bool? isAuthenticated,
    bool? isSearching,
    String? gameId,
    String? whiteId,
    String? blackId,
    String? yourColor,
    String? initialFen,
    String? error,
  }) {
    return MatchmakingState(
      isConnected: isConnected ?? this.isConnected,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isSearching: isSearching ?? this.isSearching,
      gameId: gameId ?? this.gameId,
      whiteId: whiteId ?? this.whiteId,
      blackId: blackId ?? this.blackId,
      yourColor: yourColor ?? this.yourColor,
      initialFen: initialFen ?? this.initialFen,
      error: error ?? this.error,
    );
  }
}

class MatchmakingCubit extends Cubit<MatchmakingState> {
  final MatchmakingWebSocketService _webSocketService;
  StreamSubscription? _messageSubscription;

  MatchmakingCubit(this._webSocketService) : super(const MatchmakingState()) {
    _messageSubscription = _webSocketService.messageStream.listen(_handleMessage);
  }

  Future<void> connect(String jwtToken, {String? userId}) async {
    emit(state.copyWith(error: null));
    await _webSocketService.connect(jwtToken, userId: userId);
  }

  Future<void> findMatch({
    required String variant,
    required String timeControlType,
    required String timeControl,
    required int rating,
    required int ratingRange,
  }) async {
    emit(state.copyWith(
      isSearching: true,
      error: null,
      gameId: null,
    ));

    await _webSocketService.findMatch(
      variant: variant,
      timeControlType: timeControlType,
      timeControl: timeControl,
      rating: rating,
      ratingRange: ratingRange,
    );
  }

  void cancelSearch() {
    _webSocketService.cancelSearch();
    emit(state.copyWith(
      isSearching: false,
      gameId: null,
    ));
  }

  void _handleMessage(Map<String, dynamic> data) {
    if (data.containsKey('authenticated')) {
      emit(state.copyWith(
        isAuthenticated: data['authenticated'] == true,
        isConnected: true,
      ));
    } else if (data.containsKey('match_found')) {
      if (data['match_found'] == true) {
        emit(state.copyWith(
          isSearching: false,
          gameId: data['game_id'],
          whiteId: data['white_id'],
          blackId: data['black_id'],
          yourColor: data['your_color'],
          initialFen: data['initial_fen'],
        ));
      }
    } else if (data.containsKey('error')) {
      emit(state.copyWith(
        isSearching: false,
        error: data['error'],
      ));
    } else if (data.containsKey('game_over')) {
      // Handle game over
    }
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    _webSocketService.disconnect();
    return super.close();
  }
}