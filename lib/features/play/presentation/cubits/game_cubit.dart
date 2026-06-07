// import 'dart:async';
// import 'dart:math';
// import 'package:bishop/bishop.dart' as bishop;
// import 'package:client/core/providers/locale_provider.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:squares/squares.dart';
// import 'package:square_bishop/square_bishop.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
//
// import '../../domain/entities/engine_config.dart';
// import '../../domain/entities/game_config.dart';
// import '../../domain/services/game_controller.dart';
// import '../../domain/services/online_controller.dart';
// import '../../domain/services/game_service.dart';
// import '../../domain/repositories/rating_repository.dart';
// import '../../game_di.dart';
// import 'game_state.dart';
//
// class GameCubit extends Cubit<PlayGameState> {
//   final GameConfig config;
//   final RatingRepository? ratingRepository;
//   final GameService? _gameService;
//   final LocaleProvider _locale;
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
//   StreamSubscription<Map<String, dynamic>>? _gameStreamSubscription;
//   RealtimeChannel? _presenceChannel;
//
//   String? _manualResult;
//   bool _isFlipped = false;
//
//   Move? _premove;
//
//   StreamSubscription<bool>? _thinkingSubscription;
//   StreamSubscription<String>? _opponentMoveSubscription;
//
//   final List<_HistoryEntry> _history = [];
//   int _historyIndex = -1;
//
//   bool get _isReviewing => _historyIndex >= 0;
//
//   GameCubit(
//       this.config,
//       this._locale, {
//         this.ratingRepository,
//         GameService? gameService,
//       })  : _gameService = gameService,
//         super(PlayGameState(
//         squaresState: SquaresState.initial(config.variant.boardSize.h),
//       )) {
//     _initializeGameController();
//     if (config.isOnline && _gameService != null) {
//       _initializeAuthoritativeClock();
//     }
//     _start();
//   }
//
//   // ─────────────────────────────────────────────────────────────────
//   // Инициализация
//   // ─────────────────────────────────────────────────────────────────
//
//   void _initializeGameController() {
//     String mode;
//     if (config.isOnline) {
//       mode = 'online';
//     } else if (config.isVsBot) {
//       mode = 'bot';
//     } else {
//       mode = 'local';
//     }
//     _gameController = sl<GameController>(param1: mode, param2: config);
//     _listenToController(_gameController!);
//   }
//
//   void _listenToController(GameController controller) {
//     _thinkingSubscription?.cancel();
//     _opponentMoveSubscription?.cancel();
//
//     _thinkingSubscription = controller.opponentThinkingStream.listen((isThinking) {
//       if (isClosed) return;
//       _botThinking = isThinking;
//       emit(state.copyWith(isBotThinking: _botThinking));
//     });
//
//     // ✅ Подписка на ходы оппонента (только для онлайн)
//     if (controller is OnlineController) {
//       _opponentMoveSubscription = controller.opponentMoveStream.listen((fen) {
//         if (isClosed) return;
//         debugPrint('🎯 [GameCubit] Opponent move received: $fen');
//         _applyOpponentFen(fen);
//       });
//     }
//   }
//
//   void _initializeAuthoritativeClock() {
//     if (config.gameId == null || _gameService == null) return;
//
//     final gameId = config.gameId!;
//
//     // ✅ ТОЛЬКО gamesStream — для часов и статуса игры
//     _gameStreamSubscription = _gameService.gamesStream(gameId).listen((gameData) {
//       if (isClosed || gameData.isEmpty) return;
//       _syncClockWithServer(gameData);
//
//       // Проверяем конец игры
//       final status = gameData['status'] as String?;
//       if (status != null && status != 'active' && status != 'in_progress') {
//         _stopTimer();
//         final winner = gameData['winner'] as String?;
//         if (!isClosed) {
//           emit(state.copyWith(
//             isGameOver: true,
//             result: _formatResultFromStatus(status, winner),
//           ));
//         }
//       }
//     });
//
//     // ❌ УДАЛЕНО: trackGamePresence (его больше нет в GameService)
//   }
//
//   String _formatResultFromStatus(String status, String? winner) {
//     if (status == 'resigned') {
//       return 'Resigned — $winner wins';
//     } else if (status == 'checkmate') {
//       return 'Checkmate — $winner wins';
//     } else if (status == 'timeout') {
//       return 'Time out — $winner wins';
//     } else if (status == 'draw') {
//       return 'Draw';
//     }
//     return 'Game ended: $status';
//   }
//
//   void _syncClockWithServer(Map<String, dynamic> gameData) {
//     final whiteRemaining = Duration(
//       seconds: (gameData['white_remaining_time'] as num?)?.toInt() ?? 0,
//     );
//     final blackRemaining = Duration(
//       seconds: (gameData['black_remaining_time'] as num?)?.toInt() ?? 0,
//     );
//
//     if (whiteRemaining != Duration.zero || blackRemaining != Duration.zero) {
//       _whiteTime = whiteRemaining;
//       _blackTime = blackRemaining;
//
//       if (!isClosed) {
//         emit(state.copyWith(
//           whiteTime: _whiteTime,
//           blackTime: _blackTime,
//         ));
//       }
//     }
//   }
//
//   // ─────────────────────────────────────────────────────────────────
//   // Ход игрока
//   // ─────────────────────────────────────────────────────────────────
//
//   Future<void> makeMove(Move move) async {
//     if (_isMakingMove) return;
//     if (_game == null || _botThinking || _game!.gameOver) return;
//     if (!config.isLocal && _game!.turn != config.humanPlayer.value) return;
//     if (_isReviewing) {
//       _exitReview();
//       return;
//     }
//
//     _isMakingMove = true;
//     try {
//       final prevTurn = _game!.turn;
//       final success = _game!.makeSquaresMove(move);
//       if (!success) {
//         _isMakingMove = false;
//         return;
//       }
//
//       final fenAfter = _game!.fen;
//       final sanMove = _game!.history.isNotEmpty
//           ? _game!.history.last.meta?.algebraic ?? ''
//           : '';
//
//       _addHistory(move, fenAfter, sanMove);
//
//       // ✅ ОНЛАЙН: отправляем ход через OnlineController
//       if (config.isOnline && _gameController != null && config.gameId != null) {
//         try {
//           debugPrint('📤 [GameCubit] Sending move via OnlineController');
//           await _gameController!.makeMove(move, fenAfter);
//         } catch (e) {
//           debugPrint('❌ [GameCubit] Online move error, undoing: $e');
//           _game!.undo();
//           _history.removeLast();
//           _isMakingMove = false;
//           if (!isClosed) emit(state.copyWith(fen: _game!.fen));
//           return;
//         }
//       }
//       // ЛОКАЛКА / БОТ: через контроллер (без сети)
//       else if (_gameController != null && !config.isOnline) {
//         try {
//           await _gameController!.makeMove(move, fenAfter);
//         } catch (e) {
//           debugPrint('❌ [GameCubit] Controller move error: $e');
//           _game!.undo();
//           _history.removeLast();
//           _isMakingMove = false;
//           if (!isClosed) emit(state.copyWith(fen: _game!.fen));
//           return;
//         }
//       }
//
//       _afterMove(prevTurn);
//       _clearPremoveInternal();
//
//       if (_game!.gameOver) {
//         _stopTimer();
//         if (config.isOnline && config.gameId != null) _calculateRatingAfterGame();
//         if (!isClosed) {
//           emit(state.copyWith(
//             isGameOver: true,
//             result: _manualResult ?? _formatBishopResult(_game!.result),
//           ));
//         }
//         _isMakingMove = false;
//         return;
//       }
//
//       _updateState();
//
//       if (_isBotTurn) await _botMove();
//     } finally {
//       _isMakingMove = false;
//     }
//   }
//
//   // ─────────────────────────────────────────────────────────────────
//   // Применение хода оппонента
//   // ─────────────────────────────────────────────────────────────────
//
//   void _applyOpponentFen(String fen) {
//     if (isClosed || _game == null) return;
//     if (fen == _game!.fen) return;
//
//     if (_isReviewing) _historyIndex = -1;
//
//     final prevFen = _game!.fen;
//     _game = bishop.Game(variant: config.variant, fen: fen);
//
//     _addHistory(null, fen, _guessSanFromFens(prevFen, fen));
//
//     final prevTurn = fen.split(' ')[1] == 'w' ? 1 : 0;
//     _afterMove(prevTurn);
//     _clearPremoveInternal();
//
//     if (_game!.gameOver) {
//       _stopTimer();
//       if (config.isOnline && config.gameId != null) _calculateRatingAfterGame();
//       if (!isClosed) {
//         emit(state.copyWith(
//           isGameOver: true,
//           result: _manualResult ?? _formatBishopResult(_game!.result),
//         ));
//       }
//       return;
//     }
//
//     _updateState();
//     _executePremove();
//   }
//
//   // ─────────────────────────────────────────────────────────────────
//   // Действия игры
//   // ─────────────────────────────────────────────────────────────────
//
//   void resign() {
//     if (_game == null || _game!.gameOver) return;
//     _stopTimer();
//     final opponent = config.humanPlayer.opposite.code;
//     _manualResult = _formatResult(opponent, 'resignation');
//     _gameController?.resign();
//     if (config.isOnline && config.gameId != null) _calculateRatingAfterGame();
//     if (!isClosed) emit(state.copyWith(isGameOver: true, result: _manualResult));
//   }
//
//   Future<void> offerDraw() async {
//     if (_game == null || _game!.gameOver) return;
//     await _gameController?.offerDraw();
//   }
//
//   void flipBoard() {
//     _isFlipped = !_isFlipped;
//     if (!isClosed) emit(state.copyWith(isFlipped: _isFlipped));
//   }
//
//   String _formatResult(String? winner, String? reason) {
//     String winnerText = winner ?? '';
//     String reasonKey = 'game_result_${reason?.toLowerCase().replaceAll(' ', '_')}';
//     String localizedReason = _locale.get(reasonKey);
//     if (localizedReason == reasonKey) localizedReason = reason ?? '';
//
//     return _locale
//         .get('game_result_wins_by')
//         .replaceAll('{winner}', winnerText)
//         .replaceAll('{reason}', localizedReason);
//   }
//
//   String _formatBishopResult(dynamic result) {
//     if (result == null) return '';
//     return result.toString();
//   }
//
//   // ─────────────────────────────────────────────────────────────────
//   // Premove
//   // ─────────────────────────────────────────────────────────────────
//
//   void addPremove(Move move) {
//     _premove = move;
//     if (!isClosed) emit(state.copyWith(premove: move));
//   }
//
//   void clearPremove() {
//     if (_premove != null) {
//       _premove = null;
//       if (!isClosed) emit(state.clearPremove());
//     }
//   }
//
//   void _clearPremoveInternal() {
//     if (_premove != null) {
//       _premove = null;
//       if (!isClosed) emit(state.clearPremove());
//     }
//   }
//
//   void _executePremove() {
//     if (_premove == null || _game == null || _game!.gameOver) return;
//     if (_game!.turn != config.humanPlayer.value) return;
//
//     final testGame = bishop.Game(variant: config.variant, fen: _game!.fen);
//     if (testGame.makeSquaresMove(_premove!)) {
//       final fenBefore = _game!.fen;
//       _game!.makeSquaresMove(_premove!);
//       _addHistory(_premove, _game!.fen, _guessSanFromFens(fenBefore, _game!.fen));
//       _afterMove(config.humanPlayer.value);
//       _premove = null;
//       if (!isClosed) emit(state.clearPremove());
//       _updateState();
//       if (_isBotTurn) _botMove();
//     } else {
//       _premove = null;
//       if (!isClosed) emit(state.clearPremove());
//     }
//   }
//
//   // ─────────────────────────────────────────────────────────────────
//   // Ревью истории
//   // ─────────────────────────────────────────────────────────────────
//
//   void stepBack() {
//     if (_history.isEmpty) return;
//     if (!_isReviewing) {
//       _historyIndex = _history.length - 1;
//     } else if (_historyIndex > 0) {
//       _historyIndex--;
//     } else {
//       return;
//     }
//     _emitHistoryPosition();
//   }
//
//   void stepForward() {
//     if (!_isReviewing) return;
//     if (_historyIndex < _history.length - 1) {
//       _historyIndex++;
//       _emitHistoryPosition();
//     } else {
//       _exitReview();
//     }
//   }
//
//   void jumpToStart() {
//     if (_history.isEmpty) return;
//     _historyIndex = 0;
//     _emitHistoryPosition();
//   }
//
//   void jumpToEnd() {
//     _exitReview();
//   }
//
//   void _exitReview() {
//     _historyIndex = -1;
//     _updateState();
//   }
//
//   void _emitHistoryPosition() {
//     if (_historyIndex < 0 || _historyIndex >= _history.length) return;
//     final entry = _history[_historyIndex];
//     final reviewGame = bishop.Game(variant: config.variant, fen: entry.fen);
//     final perspective = _getPerspective();
//     if (!isClosed) {
//       emit(state.copyWith(
//         squaresState: reviewGame.squaresState(perspective),
//         fen: entry.fen,
//         isReviewing: true,
//         historyIndex: _historyIndex,
//         historyLength: _history.length,
//         moveSan: _history.map((e) => e.san).toList(),
//       ));
//     }
//   }
//
//   // ─────────────────────────────────────────────────────────────────
//   // Ход бота
//   // ─────────────────────────────────────────────────────────────────
//
//   bool get _isBotTurn =>
//       config.isVsBot && _game != null && _game!.turn != config.humanPlayer.value;
//
//   Future<void> _botMove() async {
//     if (isClosed || _game == null || _game!.gameOver || !_isBotTurn) return;
//
//     _botThinking = true;
//     if (!isClosed) emit(state.copyWith(isBotThinking: true));
//
//     final delay = config.opponentType == OpponentType.randomMover
//         ? Duration(milliseconds: 300 + Random().nextInt(700))
//         : Duration(milliseconds: config.engineConfig.timeLimitMs ~/ 2);
//
//     await Future.delayed(delay);
//     if (isClosed || _game == null || _game!.gameOver || !_isBotTurn) {
//       _botThinking = false;
//       if (!isClosed) emit(state.copyWith(isBotThinking: false));
//       return;
//     }
//
//     final prevTurn = _game!.turn;
//
//     try {
//       if (config.opponentType == OpponentType.randomMover) {
//         _game!.makeRandomMove();
//       } else if (_gameController != null) {
//         final fen = _game!.fen;
//         final move = await _gameController!.getOpponentMove(fen);
//         if (isClosed) return;
//         if (move != null) {
//           final fenBefore = _game!.fen;
//           _game!.makeSquaresMove(move);
//           _addHistory(move, _game!.fen, _guessSanFromFens(fenBefore, _game!.fen));
//         }
//       } else {
//         final result = await compute(
//           _searchEngine,
//           _EngineJob(
//               fen: _game!.fen, variant: config.variant, config: config.engineConfig),
//         );
//         if (isClosed) return;
//         if (result.hasMove) {
//           _game!.makeMove(result.move!);
//         }
//       }
//     } catch (e) {
//       debugPrint('❌ [GameCubit] Bot move error: $e');
//     }
//
//     if (isClosed) return;
//
//     _afterMove(prevTurn);
//     _executePremove();
//
//     _botThinking = false;
//     if (!isClosed) emit(state.copyWith(isBotThinking: false));
//
//     if (_game?.gameOver ?? false) {
//       _stopTimer();
//       emit(state.copyWith(
//           isGameOver: true,
//           result: _manualResult ?? _formatBishopResult(_game!.result)));
//     } else {
//       _updateState();
//     }
//   }
//
//   // ─────────────────────────────────────────────────────────────────
//   // Вспомогательные
//   // ─────────────────────────────────────────────────────────────────
//
//   int _getPerspective() {
//     final base = config.humanPlayer.value;
//     return _isFlipped ? 1 - base : base;
//   }
//
//   void _addHistory(Move? move, String fen, String san) {
//     _history.add(_HistoryEntry(move: move, fen: fen, san: san));
//   }
//
//   String _guessSanFromFens(String before, String after) {
//     if (_game != null && _game!.history.isNotEmpty) {
//       return _game!.history.last.meta?.algebraic ?? '?';
//     }
//     return '?';
//   }
//
//   void _afterMove(int playerWhoMoved) {
//     if (!config.hasTimeControl) return;
//     final inc = config.timeControl.incrementDuration;
//     if (playerWhoMoved == 0) {
//       _whiteTime += inc;
//     } else {
//       _blackTime += inc;
//     }
//   }
//
//   // ─────────────────────────────────────────────────────────────────
//   // Старт / состояние
//   // ─────────────────────────────────────────────────────────────────
//
//   void _start() {
//     _game = bishop.Game(variant: config.variant, fen: config.fen);
//     if (config.hasTimeControl) {
//       _whiteTime = config.timeControl.initial;
//       _blackTime = config.timeControl.initial;
//       _startTimer();
//     }
//     _updateState();
//     if (!config.humanPlayer.isWhite && _isBotTurn) _botMove();
//   }
//
//   void _updateState() {
//     if (_game == null || isClosed || _isReviewing) return;
//     final perspective = _getPerspective();
//     emit(state.copyWith(
//       squaresState: _game!.squaresState(perspective),
//       fen: _game!.fen,
//       whiteTime: _whiteTime,
//       blackTime: _blackTime,
//       isReviewing: false,
//       historyIndex: -1,
//       historyLength: _history.length,
//       moveSan: _history.map((e) => e.san).toList(),
//     ));
//   }
//
//   // ─────────────────────────────────────────────────────────────────
//   // Таймер
//   // ─────────────────────────────────────────────────────────────────
//
//   void _startTimer() {
//     _timer = Timer.periodic(const Duration(seconds: 1), (_) {
//       if (isClosed) {
//         _stopTimer();
//         return;
//       }
//       if (_game?.gameOver ?? true) {
//         _stopTimer();
//         return;
//       }
//
//       if (_game!.turn == 0) {
//         _whiteTime = _whiteTime > Duration.zero
//             ? _whiteTime - const Duration(seconds: 1)
//             : Duration.zero;
//         if (_whiteTime == Duration.zero) {
//           _manualResult = _formatResult('Black', 'time_out');
//           _stopTimer();
//           if (!isClosed) emit(state.copyWith(isGameOver: true, result: _manualResult));
//           return;
//         }
//       } else {
//         _blackTime = _blackTime > Duration.zero
//             ? _blackTime - const Duration(seconds: 1)
//             : Duration.zero;
//         if (_blackTime == Duration.zero) {
//           _manualResult = _formatResult('White', 'time_out');
//           _stopTimer();
//           if (!isClosed) emit(state.copyWith(isGameOver: true, result: _manualResult));
//           return;
//         }
//       }
//
//       if (!isClosed) emit(state.copyWith(whiteTime: _whiteTime, blackTime: _blackTime));
//     });
//   }
//
//   void _stopTimer() {
//     _timer?.cancel();
//     _timer = null;
//   }
//
//   // ─────────────────────────────────────────────────────────────────
//   // Рейтинг
//   // ─────────────────────────────────────────────────────────────────
//
//   Future<void> _calculateRatingAfterGame() async {
//     if (!config.isOnline || config.gameId == null) return;
//     try {
//       await Supabase.instance.client.rpc('calculate_rating_after_game', params: {
//         'p_game_id': config.gameId,
//       });
//     } catch (e) {
//       debugPrint('❌ Failed to calculate rating: $e');
//     }
//   }
//
//   // ─────────────────────────────────────────────────────────────────
//   // Dispose
//   // ─────────────────────────────────────────────────────────────────
//
//   @override
//   Future<void> close() {
//     _timer?.cancel();
//     _thinkingSubscription?.cancel();
//     _opponentMoveSubscription?.cancel();
//     _gameStreamSubscription?.cancel();
//     _presenceChannel?.unsubscribe();
//     _gameController?.dispose();
//     return super.close();
//   }
// }
//
// class _HistoryEntry {
//   final Move? move;
//   final String fen;
//   final String san;
//   const _HistoryEntry({required this.move, required this.fen, required this.san});
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