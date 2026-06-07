import 'dart:async';
import 'package:squares/squares.dart';
import 'game_controller.dart';
import 'stockfish_service.dart';

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
    // Инициализируем но не владеем жизненным циклом — StockfishService singleton
    _stockfishService.initialize();
  }

  @override
  bool get isOpponentThinking => _isThinking;

  @override
  Stream<bool> get opponentThinkingStream => _thinkingController.stream;

  @override
  Future<void> makeMove(Move move, String fen) async {
    // Ход человека — бот не обрабатывает
  }

  @override
  Future<Move?> getOpponentMove(String fen) async {
    _isThinking = true;
    _thinkingController.add(true);

    try {
      final bestMoveStr = await _stockfishService.getBestMoveWithTime(
        fen,
        timeLimitMs,
      );

      if (bestMoveStr == null || bestMoveStr == '(none)') return null;
      return _parseStockfishMove(bestMoveStr);
    } catch (e) {
      // Fallback
      try {
        final bestMoveStr = await _stockfishService.getBestMove(fen, botLevel);
        if (bestMoveStr == null || bestMoveStr == '(none)') return null;
        return _parseStockfishMove(bestMoveStr);
      } catch (_) {
        return null;
      }
    } finally {
      _isThinking = false;
      _thinkingController.add(false);
    }
  }

  @override
  Future<void> resign() async {}

  @override
  Future<void> offerDraw() async {}

  Move? _parseStockfishMove(String moveStr) {
    if (moveStr.length < 4) return null;

    final from = moveStr.substring(0, 2);
    final to = moveStr.substring(2, 4);
    final promotionChar = moveStr.length > 4 ? moveStr[4] : null;

    return Move(
      from: _algebraicToSquare(from),
      to: _algebraicToSquare(to),
      promo: promotionChar,
    );
  }

  int _algebraicToSquare(String algebraic) {
    final file = algebraic[0].codeUnitAt(0) - 'a'.codeUnitAt(0);
    final rank = int.parse(algebraic[1]) - 1;
    return rank * 8 + file;
  }

  @override
  void dispose() {
    _thinkingController.close();
    // ✅ FIX: НЕ вызываем _stockfishService.dispose() —
    // StockfishService — singleton в sl, живёт всё время работы приложения.
    // Dispose будет вызван только при полном выходе.
  }
}