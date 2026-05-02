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

  // ─────────────────────────────
  // PREMOVE (FIXED)
  // ─────────────────────────────

  Move? _premove;
  Move? get premove => _premove;

  void setPremove(Move? move) {
    _premove = move;
    notifyListeners();
  }

  void clearPremove() {
    _premove = null;
    notifyListeners();
  }

  GameEngine(this.config) {
    _start();
  }

  // ─────────────────────────────
  // SNAPSHOT
  // ─────────────────────────────

  GameSnapshot get snapshot {
    if (_game == null) {
      return GameSnapshot(
        squaresState: SquaresState.initial(config.variant.boardSize.h),
      );
    }

    return GameSnapshot(
      squaresState: _game!.squaresState(config.humanPlayer.value),
      isGameOver: _game!.gameOver || _manualResult != null,
      isBotThinking: _botThinking,
      result: _manualResult ?? _game!.result?.readable,
      whiteTime: _whiteTime,
      blackTime: _blackTime,
    );
  }

  bool get isFlipped => _isFlipped;

  void flipBoard() {
    _isFlipped = !_isFlipped;
    notifyListeners();
  }

  // ─────────────────────────────
  // MOVE LOGIC (unchanged except premove safety)
  // ─────────────────────────────

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

      // ❗ IMPORTANT: clear premove after it is consumed
      clearPremove();

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
    _manualResult =
    '${config.humanPlayer.opposite.code} wins by resignation';

    notifyListeners();
  }

  // ─────────────────────────────
  // BOT (unchanged)
  // ─────────────────────────────

  bool get _isBotTurn =>
      config.isVsBot && _game!.turn != config.humanPlayer.value;

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

    _botThinking = false;
    notifyListeners();
  }

  // ─────────────────────────────
  // TIME CONTROL (unchanged)
  // ─────────────────────────────

  void _afterMove(int playerWhoMoved) {
    if (!config.hasTimeControl) return;

    final inc = config.timeControl.incrementDuration;

    if (playerWhoMoved == 0) {
      _whiteTime += inc;
    } else {
      _blackTime += inc;
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_game?.gameOver ?? true) {
        _stopTimer();
        return;
      }

      if (_game!.turn == 0) {
        _whiteTime = _whiteTime > Duration.zero
            ? _whiteTime - const Duration(seconds: 1)
            : Duration.zero;

        if (_whiteTime == Duration.zero) {
          _manualResult = 'Black wins on time';
          _stopTimer();
        }
      } else {
        _blackTime = _blackTime > Duration.zero
            ? _blackTime - const Duration(seconds: 1)
            : Duration.zero;

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
    _game = bishop.Game(
      variant: config.variant,
      fen: config.fen,
    );

    if (config.hasTimeControl) {
      _whiteTime = config.timeControl.initial;
      _blackTime = config.timeControl.initial;
      _startTimer();
    }

    notifyListeners();

    if (!config.humanPlayer.isWhite && _isBotTurn) {
      _botMove();
    }
  }
}

// ─────────────────────────────
// ENGINE ISOLATE
// ─────────────────────────────

class _EngineJob {
  final String fen;
  final bishop.Variant variant;
  final EngineConfig config;

  _EngineJob({
    required this.fen,
    required this.variant,
    required this.config,
  });
}

Future<bishop.EngineResult> _searchEngine(_EngineJob job) async {
  final game = bishop.Game(
    variant: job.variant,
    fen: job.fen,
  );

  return await bishop.Engine(game: game).search(
    timeLimit: job.config.timeLimitMs,
    timeBuffer: job.config.timeBufferMs,
  );
}