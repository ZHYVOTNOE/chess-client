import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:squares/squares.dart';
import 'game_controller.dart';
import '../../data/services/game_service.dart';

class OnlineController implements GameController {
  final GameService _gameService;
  final String gameId;
  final String userId;

  bool _isThinking = false;
  final _thinkingController = StreamController<bool>.broadcast();
  StreamSubscription? _syncSubscription;
  Move? _lastOpponentMove;
  int _currentTurn = 0; // 0 for white, 1 for black
  String? _lastKnownFen;
  bool _isReconnecting = false;
  bool _isSendingMove = false; // Track when we're sending our own move

  OnlineController({
    required GameService gameService,
    required this.gameId,
    required this.userId,
  }) : _gameService = gameService {
    _startSync();
    _loadInitialState();
  }

  @override
  bool get isOpponentThinking => _isThinking;

  @override
  Stream<bool> get opponentThinkingStream => _thinkingController.stream;

  @override
  Future<void> makeMove(Move move, String fen) async {
    try {
      _isSendingMove = true;
      // Convert move to string format for storage
      final moveStr = _moveToString(move);

      debugPrint('📤 [OnlineController] Sending move: $moveStr with FEN: $fen');

      await _gameService.makeMove(
        gameId: gameId,
        move: moveStr,
        fen: fen,
        userId: userId,
      );

      debugPrint('✅ [OnlineController] Move sent successfully');
      
      // Update last known FEN after successful move
      _lastKnownFen = fen;
    } catch (e) {
      // Network error - mark for reconnection
      debugPrint('❌ [OnlineController] Move failed: $e');
      _isReconnecting = true;
      throw Exception('Failed to make move: $e');
    } finally {
      _isSendingMove = false;
    }
  }

  @override
  Future<Move?> getOpponentMove(String fen) async {
    // Online moves come via Realtime subscription, not this method
    // This method returns the last move received from sync
    final move = _lastOpponentMove;
    _lastOpponentMove = null;
    return move;
  }

  @override
  Future<void> resign() async {
    try {
      await _gameService.resign(
        gameId: gameId,
        userId: userId,
      );
    } catch (e) {
      throw Exception('Failed to resign: $e');
    }
  }

  @override
  Future<void> offerDraw() async {
    try {
      await _gameService.offerDraw(
        gameId: gameId,
        userId: userId,
      );
    } catch (e) {
      throw Exception('Failed to offer draw: $e');
    }
  }

  void _startSync() {
    _syncSubscription = _gameService.syncStream(gameId).listen(
      (gameData) {
        _handleGameUpdate(gameData);
        _isReconnecting = false;
      },
      onError: (error) {
        debugPrint('Sync stream error: $error');
        _isReconnecting = true;
        _thinkingController.add(false);
        // Attempt to reconnect after delay
        Future.delayed(const Duration(seconds: 3), () {
          _loadInitialState();
        });
      },
    );
  }

  Future<void> _loadInitialState() async {
    try {
      final gameData = await _gameService.getGame(gameId);
      if (gameData != null) {
        _handleGameUpdate(gameData);
      }
    } catch (e) {
      debugPrint('Failed to load initial game state: $e');
    }
  }

  void _handleGameUpdate(Map<String, dynamic> gameData) {
    final fen = gameData['fen'] as String?;
    final lastMove = gameData['last_move'] as String?;
    final status = gameData['status'] as String?;
    final drawOfferedBy = gameData['draw_offered_by'] as String?;
    final movedBy = gameData['moved_by'] as String?;

    debugPrint('📥 [OnlineController] Received update: FEN=$fen, lastMove=$lastMove, movedBy=$movedBy');

    // Update current turn based on FEN
    if (fen != null) {
      _currentTurn = fen.split(' ')[1] == 'w' ? 0 : 1;
      _lastKnownFen = fen;
    }

    // Skip processing if this is our own move (just sent it)
    if (_isSendingMove && movedBy == userId) {
      debugPrint('⏭️ [OnlineController] Skipping own move from stream');
      return;
    }

    // Check if opponent made a move
    if (lastMove != null && _isOpponentMove(movedBy)) {
      debugPrint('♟️ [OnlineController] Opponent made move: $lastMove');
      _isThinking = false;
      _thinkingController.add(false);
      _lastOpponentMove = _stringToMove(lastMove);
    }

    // Handle draw offer
    if (drawOfferedBy != null && drawOfferedBy != userId) {
      debugPrint('🤝 [OnlineController] Draw offer received from opponent');
      // Opponent offered draw - notify UI
      _thinkingController.add(false);
    }

    // Handle game status
    if (status != null && status != 'in_progress') {
      debugPrint('🏁 [OnlineController] Game ended with status: $status');
      // Game ended - stop thinking indicator
      _isThinking = false;
      _thinkingController.add(false);
    }
  }

  bool _isOpponentMove(String? movedBy) {
    // Determine if the move was made by opponent
    // Check if the move was made by the current user
    if (movedBy == null) return false;
    return movedBy != userId;
  }

  String _moveToString(Move move) {
    // Convert squares Move to algebraic notation
    // This handles castling, en passant, and promotion
    final from = _squareToAlgebraic(move.from);
    final to = _squareToAlgebraic(move.to);
    final promotion = move.promo != null ? move.promo!.toLowerCase() : '';
    
    // Handle castling (king moves two squares)
    // e1g1 = kingside castling, e1c1 = queenside castling
    // The bishop library handles this internally via makeSquaresMove
    // We just need to ensure the FEN is updated correctly
    
    return '$from$to$promotion';
  }

  Move _stringToMove(String moveStr) {
    // Convert algebraic notation to squares Move
    // Handles: e2e4 (normal), e7e8q (promotion), e1g1 (castling)
    if (moveStr.length < 4) return Move(from: 0, to: 0);

    final from = _algebraicToSquare(moveStr.substring(0, 2));
    final to = _algebraicToSquare(moveStr.substring(2, 4));
    final promotionChar = moveStr.length > 4 ? moveStr[4] : null;

    // The squares library expects promo to be a String (piece character like 'q', 'r', 'b', 'n')
    // The promotionChar from the server is already in this format, so use it directly
    String? promoPiece = promotionChar?.toLowerCase();

    return Move(
      from: from,
      to: to,
      promo: promoPiece,
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

  String? _pieceToPromotion(int piece) {
    switch (piece) {
      case 5:
        return 'q';
      case 4:
        return 'r';
      case 3:
        return 'b';
      case 2:
        return 'n';
      default:
        return null;
    }
  }

  int? _promotionToPiece(String piece) {
    switch (piece.toLowerCase()) {
      case 'q':
        return 5;
      case 'r':
        return 4;
      case 'b':
        return 3;
      case 'n':
        return 2;
      default:
        return null;
    }
  }

  String? get lastKnownFen => _lastKnownFen;
  bool get isReconnecting => _isReconnecting;

  @override
  void dispose() {
    _syncSubscription?.cancel();
    _thinkingController.close();
  }
}
