// import 'dart:async';
// import 'dart:math';
// import 'package:bishop/bishop.dart' as bishop;
// import 'package:flutter/foundation.dart';
// import 'package:squares/squares.dart';
// import 'package:square_bishop/square_bishop.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
//
// import 'controllers/game_controller.dart';
// import 'controllers/online_controller.dart';
// import 'entities/engine_config.dart';
// import 'entities/game_config.dart';
//
//
// class GameSnapshot {
//   final SquaresState squaresState;
//   final bool isGameOver;
//   final bool isBotThinking;
//   final String? result;
//   final Duration whiteTime;
//   final Duration blackTime;
//   final String? fen;
//
//   const GameSnapshot({
//     required this.squaresState,
//     this.isGameOver = false,
//     this.isBotThinking = false,
//     this.result,
//     this.whiteTime = Duration.zero,
//     this.blackTime = Duration.zero,
//     this.fen,
//   });
// }
//
// class GameEngine extends ChangeNotifier {
//   final GameConfig config;
//   GameController? _gameController;
//
//   bishop.Game? _game;
//   Timer? _timer;
//
//   bool _botThinking = false;
//   bool _isMakingMove = false;
//
//   Duration _whiteTime = Duration.zero;
//   Duration _blackTime = Duration.zero;
//
//   String? _manualResult;
//   bool _isFlipped = false;
//
//   // 🔥 ЛИЧЕСС-СТИЛЬ ПРЕМУВ (только один ход)
//   Move? _premove;
//   Move? get premove => _premove;
//
//   StreamSubscription<bool>? _thinkingSubscription;
//
//   void addPremove(Move move) {
//     debugPrint('🎯 [Premove] Set: ${move.from}→${move.to} (replacing previous)');
//     _premove = move;
//     notifyListeners();
//   }
//
//   void clearPremove() {
//     debugPrint('🚫 [Engine] clearPremove called');
//     if (_premove != null) {
//       _premove = null;
//       debugPrint('✅ [Engine] Premove cleared');
//       notifyListeners();
//     }
//   }
//
//   GameEngine(this.config) {
//     _start();
//   }
//
//   /// Set the GameController based on game mode
//   void setGameController(GameController controller) {
//     _gameController?.dispose();
//     _gameController = controller;
//
//     // Listen to opponent thinking state
//     _thinkingSubscription?.cancel();
//     _thinkingSubscription = controller.opponentThinkingStream.listen((isThinking) {
//       _botThinking = isThinking;
//       notifyListeners();
//
//       // If this is an OnlineController and it's reconnecting, sync board state
//       if (controller is OnlineController && controller.isReconnecting) {
//         debugPrint('🔄 [GameEngine] Controller is reconnecting, syncing board');
//         _syncBoardFromServer(controller);
//       }
//     });
//   }
//
//   Future<void> _syncBoardFromServer(OnlineController controller) async {
//     try {
//       final serverFen = controller.lastKnownFen;
//       final currentFen = _game?.fen;
//
//       debugPrint('🔄 [GameEngine] Syncing board: current=$currentFen, server=$serverFen');
//
//       if (serverFen != null && _game != null) {
//         // Only sync if the FENs are different (avoid unnecessary rebuilds)
//         if (serverFen != currentFen) {
//           debugPrint('🔄 [GameEngine] FENs differ, rebuilding game from server');
//           // Rebuild game from server FEN to ensure synchronization
//           _game = bishop.Game(variant: config.variant, fen: serverFen);
//           notifyListeners();
//           debugPrint('✅ [GameEngine] Board synced from server FEN: $serverFen');
//         } else {
//           debugPrint('⏭️ [GameEngine] FENs match, skipping sync');
//         }
//       }
//     } catch (e) {
//       debugPrint('❌ [GameEngine] Failed to sync board from server: $e');
//     }
//   }
//
//   GameSnapshot get snapshot {
//     if (_game == null) {
//       return GameSnapshot(
//         squaresState: SquaresState.initial(config.variant.boardSize.h),
//       );
//     }
//
//     final perspective = _getPerspective();
//
//     return GameSnapshot(
//       squaresState: _game!.squaresState(perspective),
//       isGameOver: _game!.gameOver || _manualResult != null,
//       isBotThinking: _botThinking,
//       result: _manualResult ?? _game!.result?.readable,
//       whiteTime: _whiteTime,
//       blackTime: _blackTime,
//       fen: _game!.fen,
//     );
//   }
//
//   int _getPerspective() {
//     final base = config.humanPlayer.value;
//     return _isFlipped ? 1 - base : base;
//   }
//
//   bool get isFlipped => _isFlipped;
//
//   void flipBoard() {
//     _isFlipped = !_isFlipped;
//     notifyListeners();
//   }
//
//   Future<void> makeMove(Move move) async {
//     if (_isMakingMove) {
//       debugPrint('⚠️ [GameEngine] Move blocked - already making a move');
//       return;
//     }
//     if (_game == null || _botThinking || _game!.gameOver) {
//       debugPrint('⚠️ [GameEngine] Move blocked - game not ready');
//       return;
//     }
//     if (_game!.turn != config.humanPlayer.value) {
//       debugPrint('⚠️ [GameEngine] Move blocked - not player turn');
//       return;
//     }
//
//     _isMakingMove = true;
//     final fenBeforeMove = _game!.fen;
//     debugPrint('🎮 [GameEngine] Making move: ${move.from}→${move.to}, FEN before: $fenBeforeMove');
//
//     try {
//       final prevTurn = _game!.turn;
//       final success = _game!.makeSquaresMove(move);
//       if (!success) {
//         debugPrint('❌ [GameEngine] Invalid move rejected');
//         return;
//       }
//
//       final fenAfterMove = _game!.fen;
//       debugPrint('✅ [GameEngine] Move applied locally, FEN after: $fenAfterMove');
//
//       // Send move to GameController if it's an online game
//       if (_gameController != null) {
//         try {
//           await _gameController!.makeMove(move, fenAfterMove);
//           debugPrint('📤 [GameEngine] Move sent to server successfully');
//         } catch (e) {
//           // Network error - revert the move locally
//           debugPrint('❌ [GameEngine] Network error, calling undo(): $e');
//           _game!.undo(); // Revert the move
//           final fenAfterUndo = _game!.fen;
//           debugPrint('↩️ [GameEngine] After undo, FEN: $fenAfterUndo');
//           _isMakingMove = false;
//           notifyListeners();
//           rethrow;
//         }
//       }
//
//       _afterMove(prevTurn);
//       clearPremove(); // Обычный ход сбрасывает очередь
//
//       if (_game!.gameOver) {
//         _stopTimer();
//         notifyListeners();
//         return;
//       }
//
//       notifyListeners();
//
//       if (_isBotTurn) {
//         await _botMove();
//       }
//     } finally {
//       _isMakingMove = false;
//     }
//   }
//
//   void resign() {
//     if (_game == null || _game!.gameOver) return;
//     _stopTimer();
//     _manualResult = '${config.humanPlayer.opposite.code} wins by resignation';
//
//     // Notify GameController
//     _gameController?.resign();
//
//     // Calculate rating after game if it's an online game
//     if (config.isOnline && config.gameId != null) {
//       _calculateRatingAfterGame();
//     }
//
//     notifyListeners();
//   }
//
//   Future<void> offerDraw() async {
//     if (_game == null || _game!.gameOver) return;
//
//     // Notify GameController
//     await _gameController?.offerDraw();
//   }
//
//   bool get _isBotTurn => config.isVsBot && _game!.turn != config.humanPlayer.value;
//
//   Future<void> _botMove() async {
//     if (_game == null || _game!.gameOver || !_isBotTurn) return;
//
//     _botThinking = true;
//     notifyListeners();
//
//     final delay = config.opponentType == OpponentType.randomMover
//         ? Duration(milliseconds: 300 + Random().nextInt(700))
//         : Duration(milliseconds: config.engineConfig.timeLimitMs ~/ 2);
//
//     await Future.delayed(delay);
//
//     if (_game == null || _game!.gameOver || !_isBotTurn) {
//       _botThinking = false;
//       notifyListeners();
//       return;
//     }
//
//     final prevTurn = _game!.turn;
//
//     if (config.opponentType == OpponentType.randomMover) {
//       _game!.makeRandomMove();
//     } else {
//       // Use GameController if available (for Stockfish)
//       if (_gameController != null) {
//         final fen = _game!.fen;
//         final move = await _gameController!.getOpponentMove(fen);
//         if (move != null) {
//           _game!.makeSquaresMove(move);
//         }
//       } else {
//         // Fallback to bishop.Engine
//         final result = await compute(
//           _searchEngine,
//           _EngineJob(
//             fen: _game!.fen,
//             variant: config.variant,
//             config: config.engineConfig,
//           ),
//         );
//
//         if (result.hasMove) {
//           _game!.makeMove(result.move!);
//         }
//       }
//     }
//
//     _afterMove(prevTurn);
//
//     // 🔥 ПОСЛЕ ХОДА БОТА ИСПОЛНЯЕМ ПРЕМУВ (Личесс-стиль)
//     _executePremove();
//
//     _botThinking = false;
//     notifyListeners();
//   }
//
//   // 🔥 Исполняет премув (Личесс-стиль: один ход, мгновенно)
//   void _executePremove() {
//     if (_premove == null || _game == null || _game!.gameOver) {
//       debugPrint('🔄 [Premove] No premove or game over');
//       return;
//     }
//
//     if (_game!.turn != config.humanPlayer.value) {
//       debugPrint('🔄 [Premove] Not player turn');
//       return;
//     }
//
//     debugPrint('🔍 [Premove] Testing: ${_premove!.from}→${_premove!.to}');
//
//     final testGame = bishop.Game(variant: config.variant, fen: _game!.fen);
//
//     if (testGame.makeSquaresMove(_premove!)) {
//       debugPrint('✅ [Premove] Executed instantly (0.0s penalty)');
//       _game!.makeSquaresMove(_premove!);
//       _afterMove(config.humanPlayer.value);
//       _premove = null;
//       notifyListeners();
//
//       // Если после нашего хода снова ход бота -> запускаем его
//       if (_isBotTurn) {
//         debugPrint('🤖 [Premove] Bot turn, calling _botMove');
//         _botMove();
//       }
//     } else {
//       debugPrint('❌ [Premove] Illegal, clearing');
//       _premove = null;
//       notifyListeners();
//     }
//   }
//
//   void _afterMove(int playerWhoMoved) {
//     if (!config.hasTimeControl) return;
//     final inc = config.timeControl.incrementDuration;
//     if (playerWhoMoved == 0) _whiteTime += inc;
//     else _blackTime += inc;
//   }
//
//   Future<void> _calculateRatingAfterGame() async {
//     if (!config.isOnline || config.gameId == null) return;
//
//     try {
//       // Import GameService via dependency injection
//       // For now, we'll use Supabase directly
//       final client = Supabase.instance.client;
//       await client.rpc('calculate_rating_after_game', params: {
//         'p_game_id': config.gameId,
//       });
//       debugPrint('Rating calculated for game ${config.gameId}');
//     } catch (e) {
//       debugPrint('Failed to calculate rating: $e');
//     }
//   }
//
//   void _startTimer() {
//     _timer = Timer.periodic(const Duration(seconds: 1), (_) {
//       if (_game?.gameOver ?? true) {
//         _stopTimer();
//         return;
//       }
//
//       if (_game!.turn == 0) {
//         _whiteTime = _whiteTime > Duration.zero ? _whiteTime - const Duration(seconds: 1) : Duration.zero;
//         if (_whiteTime == Duration.zero) {
//           _manualResult = 'Black wins on time';
//           _stopTimer();
//         }
//       } else {
//         _blackTime = _blackTime > Duration.zero ? _blackTime - const Duration(seconds: 1) : Duration.zero;
//         if (_blackTime == Duration.zero) {
//           _manualResult = 'White wins on time';
//           _stopTimer();
//         }
//       }
//       notifyListeners();
//     });
//   }
//
//   void _stopTimer() {
//     _timer?.cancel();
//     _timer = null;
//   }
//
//   void _start() {
//     _game = bishop.Game(variant: config.variant, fen: config.fen);
//     debugPrint('🎮 [GameEngine] Game started with FEN: ${config.fen}');
//     if (config.hasTimeControl) {
//       _whiteTime = config.timeControl.initial;
//       _blackTime = config.timeControl.initial;
//       _startTimer();
//     }
//     notifyListeners();
//     if (!config.humanPlayer.isWhite && _isBotTurn) _botMove();
//   }
//
//   @override
//   void dispose() {
//     _timer?.cancel();
//     _thinkingSubscription?.cancel();
//     _gameController?.dispose();
//     super.dispose();
//   }
// }
//
// class _EngineJob {
//   final String fen;
//   final bishop.Variant variant;
//   final EngineConfig config;
//   _EngineJob({required this.fen, required this.variant, required this.config});
// }
//
// Future<bishop.EngineResult> _searchEngine(_EngineJob job) async {
//   final game = bishop.Game(variant: job.variant, fen: job.fen);
//   return await bishop.Engine(game: game).search(
//     timeLimit: job.config.timeLimitMs,
//     timeBuffer: job.config.timeBufferMs,
//   );
// }
import 'dart:async';
import 'dart:math';
import 'package:bishop/bishop.dart' as bishop;
import 'package:flutter/foundation.dart';
import 'package:squares/squares.dart';
import 'package:square_bishop/square_bishop.dart';

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