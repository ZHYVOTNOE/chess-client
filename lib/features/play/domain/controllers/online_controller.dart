import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:squares/squares.dart';
import '../../../matchmaking/data/websocket_service.dart';
import 'game_controller.dart';

class OnlineController implements GameController {
  final MatchmakingWebSocketService _wsService;
  final String gameId;
  final String userId;
  final String whiteId;
  final String blackId;

  bool _isThinking = false;
  final _thinkingController = StreamController<bool>.broadcast();
  StreamSubscription? _messageSubscription;
  Move? _lastOpponentMove;
  String? _lastKnownFen;
  bool _isReconnecting = false;
  bool _isSendingMove = false;

  OnlineController({
    required MatchmakingWebSocketService wsService,
    required this.gameId,
    required this.userId,
    required this.whiteId,
    required this.blackId,
  }) : _wsService = wsService {
    _startListening();
  }

  @override
  bool get isOpponentThinking => _isThinking;

  @override
  Stream<bool> get opponentThinkingStream => _thinkingController.stream;

  void _startListening() {
    _messageSubscription = _wsService.messageStream.listen(
          (message) {
        _handleMessage(message);
      },
      onError: (error) {
        debugPrint('❌ [OnlineController] Stream error: $error');
        _isReconnecting = true;
      },
      onDone: () {
        debugPrint('🔌 [OnlineController] Stream closed');
        _isReconnecting = true;
      },
    );
  }

  void _handleMessage(Map<String, dynamic> message) {
    // Проверяем, что сообщение относится к нашей игре
    if (message['game_id'] != gameId) return;

    // Ход соперника
    if (message.containsKey('opponent_move')) {
      final moveStr = message['move'] as String?;
      final fen = message['new_fen'] as String?;
      final whiteTime = message['white_time'] as int?;
      final blackTime = message['black_time'] as int?;

      debugPrint('📨 [OnlineController] Opponent move: $moveStr, FEN: $fen');

      if (moveStr != null) {
        _lastOpponentMove = _stringToMove(moveStr);
        _lastKnownFen = fen;
        _isThinking = false;
        _thinkingController.add(false);
      }
    }

    // Игра окончена
    if (message.containsKey('game_over')) {
      debugPrint('🏁 [OnlineController] Game over: ${message['result']}');
      _isThinking = false;
      _thinkingController.add(false);
    }

    // Соперник отключился
    if (message.containsKey('opponent_disconnected')) {
      debugPrint('⚠️ [OnlineController] Opponent disconnected');
      _isThinking = true;
      _thinkingController.add(true);
    }
  }

  @override
  Future<void> makeMove(Move move, String fen) async {
    try {
      _isSendingMove = true;
      final moveStr = _moveToString(move);

      debugPrint('📤 [OnlineController] Sending move: $moveStr, FEN: $fen');

      _wsService.sendMove(
        gameId: gameId,
        move: moveStr,
        whiteTime: 180, // TODO: передавать реальное время
        blackTime: 180,
      );

      _lastKnownFen = fen;
      debugPrint('✅ [OnlineController] Move sent successfully');
    } catch (e) {
      debugPrint('❌ [OnlineController] Move failed: $e');
      _isReconnecting = true;
      throw Exception('Failed to make move: $e');
    } finally {
      _isSendingMove = false;
    }
  }

  @override
  Future<Move?> getOpponentMove(String fen) async {
    final move = _lastOpponentMove;
    _lastOpponentMove = null;
    return move;
  }

  @override
  Future<void> resign() async {
    try {
      _wsService.resign(gameId: gameId);
    } catch (e) {
      throw Exception('Failed to resign: $e');
    }
  }

  @override
  Future<void> offerDraw() async {
    // TODO: реализовать предложение ничьей
    debugPrint('🤝 [OnlineController] Draw offer not implemented yet');
  }

  String _moveToString(Move move) {
    final from = _squareToAlgebraic(move.from);
    final to = _squareToAlgebraic(move.to);
    final promotion = move.promo != null ? move.promo!.toLowerCase() : '';
    return '$from$to$promotion';
  }

  Move _stringToMove(String moveStr) {
    if (moveStr.length < 4) return Move(from: 0, to: 0);

    final from = _algebraicToSquare(moveStr.substring(0, 2));
    final to = _algebraicToSquare(moveStr.substring(2, 4));
    final promotionChar = moveStr.length > 4 ? moveStr[4] : null;

    return Move(
      from: from,
      to: to,
      promo: promotionChar?.toLowerCase(),
    );
  }

  String _squareToAlgebraic(int square) {
    final file = square % 8;
    final rank = square ~/ 8;
    return '${String.fromCharCode('a'.codeUnitAt(0) + file)}${rank + 1}';
  }

  int _algebraicToSquare(String algebraic) {
    final file = algebraic[0].codeUnitAt(0) - 'a'.codeUnitAt(0);
    final rank = int.parse(algebraic[1]) - 1;
    return rank * 8 + file;
  }

  String? get lastKnownFen => _lastKnownFen;
  bool get isReconnecting => _isReconnecting;

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _thinkingController.close();
  }
}