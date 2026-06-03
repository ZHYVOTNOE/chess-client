import 'dart:async';
import 'package:squares/squares.dart';
import 'game_controller.dart';
import '../../data/services/stockfish_service.dart';

class BotController implements GameController {
  final StockfishService _stockfishService;
  final int botLevel;
  final int timeLimitMs;

  bool _isThinking = false;
  final _thinkingController = StreamController<bool>.broadcast();

  BotController({
    required StockfishService stockfishService,
    required this.botLevel,
    this.timeLimitMs = 1000,
  }) : _stockfishService = stockfishService {
    _stockfishService.initialize();
  }

  @override
  bool get isOpponentThinking => _isThinking;

  @override
  Stream<bool> get opponentThinkingStream => _thinkingController.stream;

  @override
  Future<void> makeMove(Move move, String fen) async {
    // Bot doesn't make moves for the human player
    // This is handled by the GameEngine
  }

  @override
  Future<Move?> getOpponentMove(String fen) async {
    _isThinking = true;
    _thinkingController.add(true);

    try {
      // Use Stockfish to get the best move
      final bestMoveStr = await _stockfishService.getBestMoveWithTime(
        fen,
        timeLimitMs,
      );

      if (bestMoveStr == null) return null;

      // Convert Stockfish move string to squares Move
      // Stockfish format: e2e4 or e7e8q (promotion)
      return _parseStockfishMove(bestMoveStr);
    } catch (e) {
      // Fallback to simpler evaluation if time-limited search fails
      final bestMoveStr = await _stockfishService.getBestMove(fen, botLevel);
      if (bestMoveStr == null) return null;
      return _parseStockfishMove(bestMoveStr);
    } finally {
      _isThinking = false;
      _thinkingController.add(false);
    }
  }

  @override
  Future<void> resign() async {
    // Bot doesn't resign
  }

  @override
  Future<void> offerDraw() async {
    // Bot doesn't offer draws
  }

  Move? _parseStockfishMove(String moveStr) {
    // Stockfish format: e2e4 or e7e8q (promotion)
    if (moveStr.length < 4) return null;

    final from = moveStr.substring(0, 2);
    final to = moveStr.substring(2, 4);
    final promotionChar = moveStr.length > 4 ? moveStr[4] : null;

    // Convert algebraic notation to squares Move
    // This is a simplified conversion - in production, use proper chess libraries
    return Move(
      from: _algebraicToSquare(from),
      to: _algebraicToSquare(to),
      promo: promotionChar,
    );
  }

  int _algebraicToSquare(String algebraic) {
    // Convert "e2" to square index (0-63)
    final file = algebraic[0].codeUnitAt(0) - 'a'.codeUnitAt(0);
    final rank = int.parse(algebraic[1]) - 1;
    return rank * 8 + file;
  }

  int? _promotionToPiece(String piece) {
    switch (piece.toLowerCase()) {
      case 'q':
        return 5; // Queen
      case 'r':
        return 4; // Rook
      case 'b':
        return 3; // Bishop
      case 'n':
        return 2; // Knight
      default:
        return null;
    }
  }

  @override
  void dispose() {
    _thinkingController.close();
    _stockfishService.dispose();
  }
}
