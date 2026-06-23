import 'dart:async';
import 'dart:math';
import 'package:bishop/bishop.dart' as bishop;
import 'package:flutter/foundation.dart';
import 'package:squares/squares.dart';
import 'package:square_bishop/square_bishop.dart';

import 'controllers/game_controller.dart';
import 'controllers/online_controller.dart';
import 'entities/engine_config.dart';
import 'entities/game_config.dart';

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
  GameController? _gameController;

  bishop.Game? _game;
  Timer? _timer;

  bool _botThinking = false;
  bool _isMakingMove = false;

  Duration _whiteTime = Duration.zero;
  Duration _blackTime = Duration.zero;

  String? _manualResult;
  bool _isFlipped = false;

  // Очередь премувов
  final List<Move> _premoveQueue = [];
  List<Move> get premoveQueue => List.unmodifiable(_premoveQueue);

  StreamSubscription<bool>? _thinkingSubscription;

  void addPremove(Move move) {
    debugPrint('🎯 [Engine] ADD premove: ${move.from}→${move.to}');
    _premoveQueue.add(move);
    _tick('addPremove');
  }

  void clearPremove() {
    debugPrint('🚫 [Engine] CLEAR premove queue');
    _premoveQueue.clear();
    _tick('clearPremove');
  }

  void _tick(String tag) {
    debugPrint('📡 [Engine] notifyListeners -> $tag');
    notifyListeners();
  }

  GameEngine(this.config) {
    debugPrint('🚀 [Engine] CREATED | variant=${config.variant} | fen=${config.fen}');

    // Инициализируем онлайн-контроллер если это онлайн-игра
    if (config.isOnline && config.gameId != null) {
      // Контроллер будет установлен извне через setGameController
      debugPrint('🌐 [Engine] Online game detected, waiting for controller...');
    }

    _start();
  }

  /// Устанавливает контроллер игры (онлайн или бот)
  void setGameController(GameController controller) {
    _gameController?.dispose();
    _gameController = controller;

    // Слушаем состояние "думает"
    _thinkingSubscription?.cancel();
    _thinkingSubscription = controller.opponentThinkingStream.listen((isThinking) {
      _botThinking = isThinking;
      notifyListeners();

      // Если онлайн-контроллер reconnecting, синхронизируем доску
      if (controller is OnlineController && controller.isReconnecting) {
        debugPrint('🔄 [Engine] Controller reconnecting, syncing board');
        _syncBoardFromServer(controller);
      }
    });
  }

  Future<void> _syncBoardFromServer(OnlineController controller) async {
    try {
      final serverFen = controller.lastKnownFen;
      final currentFen = _game?.fen;

      debugPrint('🔄 [Engine] Syncing board: current=$currentFen, server=$serverFen');

      if (serverFen != null && _game != null && serverFen != currentFen) {
        debugPrint('🔄 [Engine] FENs differ, rebuilding game from server');
        _game = bishop.Game(variant: config.variant, fen: serverFen);
        notifyListeners();
        debugPrint('✅ [Engine] Board synced from server FEN: $serverFen');
      }
    } catch (e) {
      debugPrint('❌ [Engine] Failed to sync board: $e');
    }
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
    debugPrint('👉 [Engine] makeMove: ${move.from}→${move.to}');

    if (_isMakingMove) {
      debugPrint('⛔ [Engine] BLOCKED: already making move');
      return;
    }

    if (_game == null || _botThinking || _game!.gameOver) {
      debugPrint('⛔ [Engine] BLOCKED: game not ready');
      return;
    }

    if (_game!.turn != config.humanPlayer.value) {
      debugPrint('⛔ [Engine] BLOCKED: not player turn');
      return;
    }

    _isMakingMove = true;

    try {
      final prevTurn = _game!.turn;
      final success = _game!.makeSquaresMove(move);

      if (!success) {
        debugPrint('❌ [Engine] Invalid move rejected');
        return;
      }

      final fenAfterMove = _game!.fen;
      debugPrint('✅ [Engine] Move applied, FEN: $fenAfterMove');

      // Отправляем ход на сервер если это онлайн-игра
      if (_gameController != null) {
        try {
          await _gameController!.makeMove(move, fenAfterMove);
          debugPrint('📤 [Engine] Move sent to server');
        } catch (e) {
          debugPrint('❌ [Engine] Network error, undoing move: $e');
          _game!.undo();
          _isMakingMove = false;
          notifyListeners();
          rethrow;
        }
      }

      _afterMove(prevTurn);
      clearPremove();

      if (_game!.gameOver) {
        _stopTimer();
        notifyListeners();
        return;
      }

      notifyListeners();

      // Если это бот и его ход - запускаем ход бота
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

    _gameController?.resign();
    notifyListeners();
  }

  Future<void> offerDraw() async {
    if (_game == null || _game!.gameOver) return;
    await _gameController?.offerDraw();
  }

  bool get _isBotTurn => config.isVsBot && _game!.turn != config.humanPlayer.value;

  Future<void> _botMove() async {
    if (_game == null || _game!.gameOver || !_isBotTurn) return;

    _botThinking = true;
    _tick('botThinking=true');

    final delay = config.opponentType == OpponentType.randomMover
        ? Duration(milliseconds: 300 + Random().nextInt(700))
        : Duration(milliseconds: config.engineConfig.timeLimitMs ~/ 2);

    await Future.delayed(delay);

    if (_game == null || _game!.gameOver || !_isBotTurn) {
      _botThinking = false;
      _tick('bot cancelled');
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
    _executeNextPremove();

    _botThinking = false;
    _tick('botThinking=false');
  }

  void _executeNextPremove() {
    while (_premoveQueue.isNotEmpty &&
        _game != null &&
        !_game!.gameOver &&
        _game!.turn == config.humanPlayer.value) {

      final premove = _premoveQueue.first;
      final testGame = bishop.Game(variant: config.variant, fen: _game!.fen);

      if (testGame.makeSquaresMove(premove)) {
        _game!.makeSquaresMove(premove);
        _afterMove(config.humanPlayer.value);
        _premoveQueue.removeAt(0);
        _tick('premove executed');

        if (_isBotTurn) {
          _botMove();
          return;
        }
      } else {
        _premoveQueue.removeAt(0);
        _tick('premove removed');
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
    debugPrint('⏱️ [Engine] TIMER START');

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_game?.gameOver ?? true) {
        _stopTimer();
        return;
      }

      if (_game!.turn == 0) {
        _whiteTime = _whiteTime > Duration.zero
            ? _whiteTime - const Duration(seconds: 1)
            : Duration.zero;
      } else {
        _blackTime = _blackTime > Duration.zero
            ? _blackTime - const Duration(seconds: 1)
            : Duration.zero;
      }

      _tick('timer');
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _start() {
    debugPrint('🎮 [Engine] START game init');

    _game = bishop.Game(variant: config.variant, fen: config.fen);
    debugPrint('♟️ [Engine] initial FEN = ${config.fen}');

    if (config.hasTimeControl) {
      _whiteTime = config.timeControl.initial;
      _blackTime = config.timeControl.initial;
      debugPrint('⏱️ [Engine] timers set: white=$_whiteTime black=$_blackTime');
      _startTimer();
    }

    _tick('start()');

    if (!config.humanPlayer.isWhite && _isBotTurn) {
      debugPrint('🤖 [Engine] bot starts first move');
      _botMove();
    }
  }

  @override
  void dispose() {
    debugPrint('💀 [Engine] DISPOSE called');
    _timer?.cancel();
    _thinkingSubscription?.cancel();
    _gameController?.dispose();
    _premoveQueue.clear();
    super.dispose();
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