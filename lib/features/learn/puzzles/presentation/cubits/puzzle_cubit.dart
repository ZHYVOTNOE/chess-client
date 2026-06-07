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

  Future<void> loadPuzzle(String userId) async {
    emit(PuzzleLoading());
    try {
      // Загружаем паззл и статистику параллельно
      final results = await Future.wait([
        getRandomPuzzle(userId),
        repository.getUserStats(userId),
      ]);

      _currentPuzzle = results[0] as Puzzle;
      final stats = results[1] as Map<String, dynamic>;

      _currentFen = _currentPuzzle!.fen;
      _game = bishop.Game(fen: _currentFen);
      _currentMoveIndex = 0;
      _isOpponentTurn = true;

      final parts = _currentFen.split(' ');
      final activeColor = parts[1];
      _userColor = (activeColor == 'w') ? 'black' : 'white';

      emit(PuzzleLoaded(
        fen: _currentFen,
        currentMoveIndex: _currentMoveIndex,
        isOpponentTurn: _isOpponentTurn,
        userColor: _userColor,
        streak: stats['streak'] as int? ?? 0,
        solvedToday: stats['solved_today'] as int? ?? 0,
        ratingProgress: 0,
      ));

      await Future.delayed(const Duration(milliseconds: 1000));
      _playOpponentMove();
    } catch (e, st) {
      print('=== PUZZLE ERROR ===');
      print('Type: ${e.runtimeType}');
      print('Message: $e');
      print('Stack: $st');
      emit(PuzzleError(message: e.toString()));
    }
  }

  void _playOpponentMove() {
    if (_currentPuzzle == null || _currentMoveIndex >= _currentPuzzle!.moves.length) return;

    final uciMove = _currentPuzzle!.moves[_currentMoveIndex];
    final success = _applyMove(uciMove);
    
    if (success) {
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
      // Bishop's makeMoveString accepts UCI format directly (e.g., 'e2e4', 'f7f8q')
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
      // Correct move
      final success = _applyMove(uciMove);
      
      if (success) {
        _currentMoveIndex++;

        if (_currentMoveIndex >= _currentPuzzle!.moves.length) {
          // Puzzle solved
          _onPuzzleSolved();
        } else {
          // Opponent's turn
          _isOpponentTurn = true;
          emit((state as PuzzleLoaded).copyWith(
            fen: _currentFen,
            currentMoveIndex: _currentMoveIndex,
            isOpponentTurn: _isOpponentTurn,
          ));

          // Auto-play opponent move after 500ms
          Future.delayed(const Duration(milliseconds: 500), () {
            _playOpponentMove();
          });
        }
      }
    } else {
      // Incorrect move - show error feedback
      emit((state as PuzzleLoaded).copyWith(
        isHintShown: true,
      ));

      // Hide hint after 500ms
      Future.delayed(const Duration(milliseconds: 500), () {
        if (state is PuzzleLoaded) {
          emit((state as PuzzleLoaded).copyWith(
            isHintShown: false,
          ));
        }
      });
    }
  }

  Future<void> _onPuzzleSolved() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    int streak = 0;
    int solvedToday = 0;

    if (userId != null && _currentPuzzle != null) {
      try {
        await repository.savePuzzleAttempt(
          userId: userId,
          puzzleId: _currentPuzzle!.id,
          isSolved: true,
        );
        // Обновляем статистику после решения
        final stats = await repository.getUserStats(userId);
        streak = stats['streak'] as int? ?? 0;
        solvedToday = stats['solved_today'] as int? ?? 0;
      } catch (e) {
        print('Error saving puzzle attempt: $e');
      }
    }

    emit(PuzzleSolved(
      fen: _currentFen,
      currentMoveIndex: _currentMoveIndex,
      userColor: _userColor,
      streak: streak,
      solvedToday: solvedToday,
      ratingProgress: 0,
    ));
  }

  void retryPuzzle() {
    if (_currentPuzzle == null) return;

    // Берём статистику из текущего стейта чтобы не терять
    int streak = 0;
    int solvedToday = 0;
    if (state is PuzzleLoaded) {
      streak = (state as PuzzleLoaded).streak;
      solvedToday = (state as PuzzleLoaded).solvedToday;
    } else if (state is PuzzleSolved) {
      streak = (state as PuzzleSolved).streak;
      solvedToday = (state as PuzzleSolved).solvedToday;
    }

    _currentFen = _currentPuzzle!.fen;
    _game = bishop.Game(fen: _currentFen);
    _currentMoveIndex = 0;
    _isOpponentTurn = true;

    emit(PuzzleLoaded(
      fen: _currentFen,
      currentMoveIndex: _currentMoveIndex,
      isOpponentTurn: _isOpponentTurn,
      userColor: _userColor,
      streak: streak,
      solvedToday: solvedToday,
    ));

    Future.delayed(const Duration(milliseconds: 500), () {
      _playOpponentMove();
    });
  }

  void showHint() {
    if (state is PuzzleLoaded) {
      emit((state as PuzzleLoaded).copyWith(
        isHintShown: true,
      ));

      // Hide hint after 2 seconds
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (state is PuzzleLoaded) {
          emit((state as PuzzleLoaded).copyWith(
            isHintShown: false,
          ));
        }
      });
    }
  }

  void loadNextPuzzle(String userId) {
    loadPuzzle(userId);
  }

  // Helper method to get hint move (for UI highlighting)
  String? getHintMove() {
    if (_currentPuzzle == null || _currentMoveIndex >= _currentPuzzle!.moves.length) {
      return null;
    }
    return _currentPuzzle!.moves[_currentMoveIndex];
  }
}