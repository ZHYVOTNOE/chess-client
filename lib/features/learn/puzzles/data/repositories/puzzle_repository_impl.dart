import 'package:client/core/error/exceptions.dart';
import '../../domain/entities/puzzle.dart';
import '../../domain/repositories/puzzle_repository.dart';
import '../datasources/puzzle_remote_datasource.dart';

class PuzzleRepositoryImpl implements PuzzleRepository {
  final PuzzleRemoteDataSource remoteDataSource;

  PuzzleRepositoryImpl(this.remoteDataSource);

  @override
  Future<Puzzle> getRandomPuzzle(String userId) async {
    try {
      // Get user's puzzle rating first
      final userRating = await remoteDataSource.getUserPuzzleRating(userId);

      final puzzle = await remoteDataSource.getRandomPuzzle(
        userRating: userRating,
      );
      return puzzle;
    } on ServerException {
      rethrow;
    }
  }

  @override
  Future<Puzzle> getPuzzleById(String puzzleId) async {
    try {
      final puzzle = await remoteDataSource.getPuzzleById(puzzleId);
      return puzzle;
    } on ServerException {
      rethrow;
    }
  }

  @override
  Future<List<Puzzle>> getPuzzlesByTheme({
    required String theme,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final puzzles = await remoteDataSource.getPuzzlesByTheme(
        theme: theme,
        limit: limit,
        offset: offset,
      );
      return puzzles;
    } on ServerException {
      rethrow;
    }
  }

  @override
  Future<bool> submitSolution({
    required String puzzleId,
    required List<String> moves,
  }) async {
    try {
      final result = await remoteDataSource.submitSolution(
        puzzleId: puzzleId,
        moves: moves,
      );
      return result;
    } on ServerException {
      rethrow;
    }
  }

  @override
  Future<void> savePuzzleAttempt({
    required String userId,
    required String puzzleId,
    required bool isSolved,
  }) async {
    try {
      await remoteDataSource.savePuzzleAttempt(
        userId: userId,
        puzzleId: puzzleId,
        isSolved: isSolved,
      );
    } on ServerException {
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      final stats = await remoteDataSource.getUserStats();
      return stats;
    } on ServerException {
      rethrow;
    }
  }

  @override
  Future<List<String>> getThemes() async {
    try {
      final themes = await remoteDataSource.getThemes();
      return themes;
    } on ServerException {
      rethrow;
    }
  }
}
