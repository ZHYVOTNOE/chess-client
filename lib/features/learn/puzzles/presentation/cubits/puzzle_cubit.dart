import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bishop/bishop.dart' as bishop;
import '../../domain/entities/puzzle.dart';
import '../../domain/usecases/get_random_puzzle.dart';
import '../../domain/usecases/submit_solution.dart';
import '../../domain/repositories/puzzle_repository.dart';

part 'puzzle_state.dart';

class PuzzleCubit extends Cubit<PuzzleState> {
  final GetRandomPuzzle getRandomPuzzle;
  final SubmitSolution submitSolution;
  final PuzzleRepository repository;

  PuzzleCubit({
    required this.getRandomPuzzle,
    required this.submitSolution,
    required this.repository,
  }) : super(PuzzleInitial());

  Puzzle? _currentPuzzle;
  String _currentFen = '';
  int _currentMoveIndex = 0;
  bool _isOpponentTurn = false;
  String _userColor = 'white';
  late bishop.Game _game;

  int _streak = 0;
  int _solvedToday = 0;
  int _userRating = 1500;
  bool _madeErrorThisPuzzle = false;
  bool _ratingPenaltyApplied = false;

  Timer? _timer;
  int _elapsedSeconds = 0;

  void _startTimer() {
    _timer?.cancel();
    _elapsedSeconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state is PuzzleLoaded) {
        _elapsedSeconds++;
        emit((state as PuzzleLoaded).copyWith(elapsedSeconds: _elapsedSeconds));
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> loadPuzzle(String userId, {bool isFirst = false}) async {
    _stopTimer();

    final savedStreak = _streak;
    final savedSolvedToday = _solvedToday;
    final savedRating = _userRating;

    emit(PuzzleLoading());
    try {
      if (isFirst) {
        final results = await Future.wait([
          getRandomPuzzle(userId),
          repository.getUserStats(userId),
        ]);
        _currentPuzzle = results[0] as Puzzle;
        final stats = results[1] as Map<String, dynamic>;
        _streak = stats['current_streak'] as int? ?? 0;
        _solvedToday = stats['solved_today'] as int? ?? 0;
        _userRating = stats['rating'] as int? ?? 1500;
      } else {
        _currentPuzzle = await getRandomPuzzle(userId);
        _streak = savedStreak;
        _solvedToday = savedSolvedToday;
        _userRating = savedRating;
      }

      _currentFen = _currentPuzzle!.fen;
      _game = bishop.Game(fen: _currentFen);
      _currentMoveIndex = 0;
      _isOpponentTurn = true;
      _madeErrorThisPuzzle = false;
      _ratingPenaltyApplied = false;
      _elapsedSeconds = 0;

      final parts = _currentFen.split(' ');
      _userColor = (parts[1] == 'w') ? 'black' : 'white';

      emit(PuzzleLoaded(
        fen: _currentFen,
        currentMoveIndex: _currentMoveIndex,
        isOpponentTurn: _isOpponentTurn,
        userColor: _userColor,
        streak: _streak,
        solvedToday: _solvedToday,
        userRating: _userRating,
        elapsedSeconds: 0,
        ratingDelta: null,
      ));

      await Future.delayed(const Duration(milliseconds: 1000));
      _playOpponentMove();
      _startTimer();
    } catch (e, st) {
      print('=== PUZZLE ERROR ===\n$e\n$st');
      emit(PuzzleError(message: e.toString()));
    }
  }

  void _playOpponentMove() {
    if (_currentPuzzle == null ||
        _currentMoveIndex >= _currentPuzzle!.moves.length) return;

    final uciMove = _currentPuzzle!.moves[_currentMoveIndex];
    if (_applyMove(uciMove)) {
      _currentMoveIndex++;
      _isOpponentTurn = false;
      if (state is PuzzleLoaded) {
        emit((state as PuzzleLoaded).copyWith(
          fen: _currentFen,
          currentMoveIndex: _currentMoveIndex,
          isOpponentTurn: _isOpponentTurn,
        ));
      }
    }
  }

  bool _applyMove(String uciMove) {
    try {
      final success = _game.makeMoveString(uciMove);
      if (success) {
        _currentFen = _game.fen;
        return true;
      }
      return false;
    } catch (e) {
      print('Error applying move: $e');
      return false;
    }
  }

  void onUserMove(String uciMove) {
    if (_currentPuzzle == null || state is! PuzzleLoaded) return;
    if (_isOpponentTurn) return;

    final expectedMove = _currentPuzzle!.moves[_currentMoveIndex];

    if (uciMove == expectedMove) {
      final success = _applyMove(uciMove);
      if (success) {
        _currentMoveIndex++;
        if (_currentMoveIndex >= _currentPuzzle!.moves.length) {
          _onPuzzleSolved();
        } else {
          _isOpponentTurn = true;
          emit((state as PuzzleLoaded).copyWith(
            fen: _currentFen,
            currentMoveIndex: _currentMoveIndex,
            isOpponentTurn: _isOpponentTurn,
            feedbackMessage: null,
            hintLevel: 0,
          ));
          Future.delayed(const Duration(milliseconds: 500), _playOpponentMove);
        }
      }
    } else {
      // Неверный ход
      _madeErrorThisPuzzle = true;

      final fenBeforeError = _currentFen;
      final gameBeforeError = bishop.Game(fen: _currentFen);
      _applyMove(uciMove);

      emit((state as PuzzleLoaded).copyWith(
        fen: _currentFen,
        feedbackMessage: 'wrong',
        hintLevel: 0,
      ));

      // Штраф рейтинга только один раз за задачу
      if (!_ratingPenaltyApplied) {
        _ratingPenaltyApplied = true;
        _applyRatingPenalty();
      }

      // Откат хода через 800ms
      Future.delayed(const Duration(milliseconds: 800), () {
        if (state is PuzzleLoaded) {
          _currentFen = fenBeforeError;
          _game = gameBeforeError;
          emit((state as PuzzleLoaded).copyWith(
            fen: _currentFen,
            streak: _streak,
          ));
        }
      });
    }
  }

  void _applyRatingPenalty() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || _currentPuzzle == null) return;

    Supabase.instance.client.rpc('complete_puzzle', params: {
      'p_user_id': userId,
      'p_puzzle_id': _currentPuzzle!.id,
      'p_puzzle_rating': _currentPuzzle!.rating,
      'p_is_solved': false,
      'p_already_penalized': false,
    }).then((result) {
      if (result != null) {
        final delta = (result['rating_delta'] as num?)?.toInt() ?? 0;
        _streak = (result['current_streak'] as num?)?.toInt() ?? 0;
        _userRating = (result['new_rating'] as num?)?.toInt() ?? _userRating;
        if (state is PuzzleLoaded) {
          emit((state as PuzzleLoaded).copyWith(
            streak: _streak,
            userRating: _userRating,
            ratingDelta: delta,
          ));
        }
      }
    }).catchError((e) => print('Rating penalty error: $e'));
  }

  Future<void> _onPuzzleSolved() async {
    _stopTimer();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    int? ratingDelta;

    if (userId != null && _currentPuzzle != null) {
      try {
        final result = await Supabase.instance.client.rpc('complete_puzzle', params: {
          'p_user_id': userId,
          'p_puzzle_id': _currentPuzzle!.id,
          'p_puzzle_rating': _currentPuzzle!.rating,
          'p_is_solved': true,
          'p_already_penalized': _ratingPenaltyApplied,
        });

        if (result != null) {
          ratingDelta = (result['rating_delta'] as num?)?.toInt();
          _streak = (result['current_streak'] as num?)?.toInt() ?? _streak;
          _solvedToday = (result['solved_today'] as num?)?.toInt() ?? _solvedToday;
          _userRating = (result['new_rating'] as num?)?.toInt() ?? _userRating;
        }
      } catch (e) {
        print('Error completing puzzle: $e');
      }
    }

    emit(PuzzleSolved(
      fen: _currentFen,
      currentMoveIndex: _currentMoveIndex,
      userColor: _userColor,
      streak: _streak,
      solvedToday: _solvedToday,
      userRating: _userRating,
      elapsedSeconds: _elapsedSeconds,
      ratingDelta: ratingDelta,
    ));
  }

  void retryPuzzle() {
    if (_currentPuzzle == null) return;
    _stopTimer();

    _currentFen = _currentPuzzle!.fen;
    _game = bishop.Game(fen: _currentFen);
    _currentMoveIndex = 0;
    _isOpponentTurn = true;
    _madeErrorThisPuzzle = false;
    _ratingPenaltyApplied = false;
    _elapsedSeconds = 0;

    emit(PuzzleLoaded(
      fen: _currentFen,
      currentMoveIndex: _currentMoveIndex,
      isOpponentTurn: _isOpponentTurn,
      userColor: _userColor,
      streak: _streak,
      solvedToday: _solvedToday,
      userRating: _userRating,
      elapsedSeconds: 0,
      ratingDelta: null,
    ));

    Future.delayed(const Duration(milliseconds: 500), () {
      _playOpponentMove();
      _startTimer();
    });
  }

  void showHint() {
    if (state is! PuzzleLoaded) return;
    final currentLevel = (state as PuzzleLoaded).hintLevel;
    // Первое нажатие — подсветка фигуры, второе — стрелка
    emit((state as PuzzleLoaded).copyWith(
      hintLevel: currentLevel >= 2 ? 2 : currentLevel + 1,
    ));
  }

  void loadNextPuzzle(String userId) => loadPuzzle(userId, isFirst: false);

  String? getHintMove() {
    if (_currentPuzzle == null ||
        _currentMoveIndex >= _currentPuzzle!.moves.length) return null;
    return _currentPuzzle!.moves[_currentMoveIndex];
  }

  @override
  Future<void> close() {
    _stopTimer();
    return super.close();
  }
}