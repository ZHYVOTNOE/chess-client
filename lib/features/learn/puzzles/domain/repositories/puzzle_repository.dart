import '../entities/puzzle.dart';

abstract class PuzzleRepository {
  /// Get a random puzzle based on user rating
  Future<Puzzle> getRandomPuzzle(String userId);

  /// Get a puzzle by ID
  Future<Puzzle> getPuzzleById(String puzzleId);

  /// Get puzzles by theme
  Future<List<Puzzle>> getPuzzlesByTheme({
    required String theme,
    int limit = 20,
    int offset = 0,
  });

  /// Submit a puzzle solution
  Future<bool> submitSolution({
    required String puzzleId,
    required List<String> moves,
  });

  /// Save a puzzle attempt
  Future<void> savePuzzleAttempt({
    required String userId,
    required String puzzleId,
    required bool isSolved,
  });

  /// Get user's puzzle statistics
  Future<Map<String, dynamic>> getUserStats(String userId);

  /// Get puzzle themes
  Future<List<String>> getThemes();
}
