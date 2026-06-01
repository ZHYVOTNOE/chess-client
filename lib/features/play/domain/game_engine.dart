import 'dart:async';
import 'dart:math';
import 'package:bishop/bishop.dart' as bishop;
import 'package:flutter/foundation.dart';
import 'package:squares/squares.dart';
import 'package:square_bishop/square_bishop.dart';

import '../presentation/widgets/engine_config.dart';
import '../presentation/widgets/game_config.dart';

class GameSnapshot {
  final SquaresState squaresState;
  final bool isGameOver;
  final bool isBotThinking;
  final String? result;
  final Duration whiteTime;
  final Duration blackTime;

  const GameSnapshot({
    required this.squaresState,
    this.isGameOver = false,
    this.isBotThinking = false,
    this.result,
    this.whiteTime = Duration.zero,
    this.blackTime = Duration.zero,
  });
}

class GameEngine extends ChangeNotifier {
  final GameConfig config;

  bishop.Game? _game;
  Timer? _timer;

  bool _botThinking = false;
  bool _isMakingMove = false;

  Duration _whiteTime = Duration.zero;
  Duration _blackTime = Duration.zero;

  String? _manualResult;
  bool _isFlipped = false;

  // 🔥 ОЧЕРЕДЬ ПРЕМУВОВ (как на Chess.com)
  final List<Move> _premoveQueue = [];
  List<Move> get premoveQueue => List.unmodifiable(_premoveQueue);

  void addPremove(Move move) {
    debugPrint('🎯 [Premove] Added: ${move.from}→${move.to}, queue: ${_premoveQueue.length + 1}');
    _premoveQueue.add(move);
    notifyListeners(); // 🔥 Обновляем UI
  }

  void clearPremove() {
    debugPrint('🚫 [Engine] clearPremove called, queue: ${_premoveQueue.length}');
    if (_premoveQueue.isNotEmpty) {
      _premoveQueue.clear();
      debugPrint('✅ [Engine] Queue cleared');
      notifyListeners(); // 🔥 Обновляем UI
    }
  }

  GameEngine(this.config) {
    _start();
  }

  GameSnapshot get snapshot {
    if (_game == null) {
      return GameSnapshot(
        squaresState: SquaresState.initial(config.variant.boardSize.h),
      );
    }

    final perspective = _getPerspective();

    return GameSnapshot(
      squaresState: _game!.squaresState(perspective),
      isGameOver: _game!.gameOver || _manualResult != null,
      isBotThinking: _botThinking,
      result: _manualResult ?? _game!.result?.readable,
      whiteTime: _whiteTime,
      blackTime: _blackTime,
    );
  }

  int _getPerspective() {
    final base = config.humanPlayer.value;
    return _isFlipped ? 1 - base : base;
  }

  bool get isFlipped => _isFlipped;

  void flipBoard() {
    _isFlipped = !_isFlipped;
    notifyListeners();
  }

  Future<void> makeMove(Move move) async {
    if (_isMakingMove) return;
    if (_game == null || _botThinking || _game!.gameOver) return;
    if (_game!.turn != config.humanPlayer.value) return;

    _isMakingMove = true;

    try {
      final prevTurn = _game!.turn;
      final success = _game!.makeSquaresMove(move);
      if (!success) return;

      _afterMove(prevTurn);
      clearPremove(); // Обычный ход сбрасывает очередь

      if (_game!.gameOver) {
        _stopTimer();
        notifyListeners();
        return;
      }

      notifyListeners();

      if (_isBotTurn) {
        await _botMove();
      }
    } finally {
      _isMakingMove = false;
    }
  }

  void resign() {
    if (_game == null || _game!.gameOver) return;
    _stopTimer();
    _manualResult = '${config.humanPlayer.opposite.code} wins by resignation';
    notifyListeners();
  }

  bool get _isBotTurn => config.isVsBot && _game!.turn != config.humanPlayer.value;

  Future<void> _botMove() async {
    if (_game == null || _game!.gameOver || !_isBotTurn) return;

    _botThinking = true;
    notifyListeners();

    final delay = config.opponentType == OpponentType.randomMover
        ? Duration(milliseconds: 300 + Random().nextInt(700))
        : Duration(milliseconds: config.engineConfig.timeLimitMs ~/ 2);

    await Future.delayed(delay);

    if (_game == null || _game!.gameOver || !_isBotTurn) {
      _botThinking = false;
      notifyListeners();
      return;
    }

    final prevTurn = _game!.turn;

    if (config.opponentType == OpponentType.randomMover) {
      _game!.makeRandomMove();
    } else {
      final result = await compute(
        _searchEngine,
        _EngineJob(
          fen: _game!.fen,
          variant: config.variant,
          config: config.engineConfig,
        ),
      );

      if (result.hasMove) {
        _game!.makeMove(result.move!);
      }
    }

    _afterMove(prevTurn);

    // 🔥 ПОСЛЕ ХОДА БОТА ИСПОЛНЯЕМ СЛЕДУЮЩИЙ ПРЕМУВ ИЗ ОЧЕРЕДИ
    _executeNextPremove();

    _botThinking = false;
    notifyListeners();
  }

  // 🔥 Исполняет следующий легальный премув из очереди (рекурсивно)
  void _executeNextPremove() {
    debugPrint('🔄 [Premove] Checking queue: ${_premoveQueue.length} items');

    while (_premoveQueue.isNotEmpty &&
        _game != null &&
        !_game!.gameOver &&
        _game!.turn == config.humanPlayer.value) {

      final premove = _premoveQueue.first;
      debugPrint('🔍 [Premove] Testing: ${premove.from}→${premove.to}');

      final testGame = bishop.Game(variant: config.variant, fen: _game!.fen);

      if (testGame.makeSquaresMove(premove)) {
        debugPrint('✅ [Premove] Executed');
        _game!.makeSquaresMove(premove);
        _afterMove(config.humanPlayer.value);
        _premoveQueue.removeAt(0);
        notifyListeners();

        // Если после нашего хода снова ход бота -> запускаем его
        if (_isBotTurn) {
          debugPrint('🤖 [Premove] Bot turn, calling _botMove');
          _botMove();
          return; // Выходим, бот сам вызовет _executeNextPremove после своего хода
        }
      } else {
        debugPrint('❌ [Premove] Illegal, removing');
        _premoveQueue.removeAt(0);
        notifyListeners();
      }
    }
  }

  void _afterMove(int playerWhoMoved) {
    if (!config.hasTimeControl) return;
    final inc = config.timeControl.incrementDuration;
    if (playerWhoMoved == 0) _whiteTime += inc;
    else _blackTime += inc;
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_game?.gameOver ?? true) {
        _stopTimer();
        return;
      }

      if (_game!.turn == 0) {
        _whiteTime = _whiteTime > Duration.zero ? _whiteTime - const Duration(seconds: 1) : Duration.zero;
        if (_whiteTime == Duration.zero) {
          _manualResult = 'Black wins on time';
          _stopTimer();
        }
      } else {
        _blackTime = _blackTime > Duration.zero ? _blackTime - const Duration(seconds: 1) : Duration.zero;
        if (_blackTime == Duration.zero) {
          _manualResult = 'White wins on time';
          _stopTimer();
        }
      }
      notifyListeners();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _start() {
    _game = bishop.Game(variant: config.variant, fen: config.fen);
    if (config.hasTimeControl) {
      _whiteTime = config.timeControl.initial;
      _blackTime = config.timeControl.initial;
      _startTimer();
    }
    notifyListeners();
    if (!config.humanPlayer.isWhite && _isBotTurn) _botMove();
  }
}

class _EngineJob {
  final String fen;
  final bishop.Variant variant;
  final EngineConfig config;
  _EngineJob({required this.fen, required this.variant, required this.config});
}

Future<bishop.EngineResult> _searchEngine(_EngineJob job) async {
  final game = bishop.Game(variant: job.variant, fen: job.fen);
  return await bishop.Engine(game: game).search(
    timeLimit: job.config.timeLimitMs,
    timeBuffer: job.config.timeBufferMs,
  );
}