import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:squares/squares.dart';
import 'game_controller.dart';
import 'game_service.dart';

/// Контроллер для онлайн-игры.
///
/// Подписывается на таблицу moves и пушит новые ходы оппонента
/// через opponentMoveStream.
class OnlineController implements GameController {
  final GameService _gameService;
  final String gameId;
  final String userId;

  bool _isThinking = false;
  String? _lastKnownFen;
  bool _isSendingMove = false;

  final _thinkingController = StreamController<bool>.broadcast();
  final _opponentMoveController = StreamController<String>.broadcast();

  StreamSubscription? _movesSub;

  /// Публичный стрим с FEN от ходов оппонента.
  /// GameCubit должен слушать его.
  Stream<String> get opponentMoveStream => _opponentMoveController.stream;

  OnlineController({
    required GameService gameService,
    required this.gameId,
    required this.userId,
  }) : _gameService = gameService {
    _subscribeToMoves();
    _loadInitialState();
  }

  @override
  bool get isOpponentThinking => _isThinking;

  @override
  Stream<bool> get opponentThinkingStream => _thinkingController.stream;

  String? get lastKnownFen => _lastKnownFen;

  @override
  Future<void> makeMove(Move move, String fen) async {
    _isSendingMove = true;
    try {
      // Конвертируем Move в UCI строку
      final uci = _moveToUci(move);
      debugPrint('📤 [OnlineController] Sending: uci=$uci fen=$fen');

      await _gameService.makeMove(
        gameId: gameId,
        uci: uci,
        fen: fen,
        userId: userId,
      );

      _lastKnownFen = fen;
      debugPrint('✅ [OnlineController] Move sent OK');
    } catch (e) {
      debugPrint('❌ [OnlineController] makeMove failed: $e');
      rethrow;
    } finally {
      _isSendingMove = false;
    }
  }

  @override
  Future<Move?> getOpponentMove(String fen) async => null;

  @override
  Future<void> resign() => _gameService.resign(gameId: gameId, userId: userId);

  @override
  Future<void> offerDraw() => _gameService.offerDraw(gameId: gameId, userId: userId);

  @override
  void dispose() {
    _movesSub?.cancel();
    _thinkingController.close();
    _opponentMoveController.close();
  }

  // ─────────────────────────────────────────────────────────────────
  // Подписка на moves
  // ─────────────────────────────────────────────────────────────────

  void _subscribeToMoves() {
    debugPrint('🔌 [OnlineController] Subscribing to moves for game=$gameId');

    _movesSub = _gameService.movesStream(gameId).listen(
          (moveRow) {
        if (moveRow.isEmpty) return;

        final uci = moveRow['uci'] as String?;
        final fenAfter = moveRow['fen_after'] as String?;
        final moveNumber = moveRow['move_number'] as int?;
        final playerId = moveRow['player_id'] as String?;

        debugPrint('📥 [OnlineController] move #$moveNumber uci=$uci player=$playerId');

        if (fenAfter == null) return;

        // Пропускаем если FEN не изменился
        if (fenAfter == _lastKnownFen) {
          debugPrint('⏭️  [OnlineController] Same FEN, skipping');
          return;
        }

        // Пропускаем свои собственные ходы
        if (_isSendingMove || playerId == userId) {
          debugPrint('⏭️  [OnlineController] Own move, updating cache only');
          _lastKnownFen = fenAfter;
          return;
        }

        // Ход оппонента!
        debugPrint('♟️  [OnlineController] OPPONENT MOVE: $fenAfter');
        _lastKnownFen = fenAfter;
        _isThinking = false;
        _thinkingController.add(false);

        if (!_opponentMoveController.isClosed) {
          _opponentMoveController.add(fenAfter);
        }
      },
      onError: (e) {
        debugPrint('⚠️  [OnlineController] moves stream error: $e');
      },
    );
  }

  Future<void> _loadInitialState() async {
    try {
      final data = await _gameService.getGame(gameId);
      if (data != null) {
        final fen = data['fen'] as String?;
        if (fen != null) {
          _lastKnownFen = fen;
          debugPrint('📋 [OnlineController] Initial FEN: $fen');
        }
      }
    } catch (e) {
      debugPrint('❌ [OnlineController] loadInitialState failed: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // UCI helpers
  // ─────────────────────────────────────────────────────────────────

  String _moveToUci(Move move) {
    final from = _squareToAlgebraic(move.from);
    final to = _squareToAlgebraic(move.to);
    final promo = move.promo?.toLowerCase() ?? '';
    return '$from$to$promo';
  }

  String _squareToAlgebraic(int square) {
    final file = square % 8;
    final rank = square ~/ 8;
    return '${String.fromCharCode('a'.codeUnitAt(0) + file)}${rank + 1}';
  }
}