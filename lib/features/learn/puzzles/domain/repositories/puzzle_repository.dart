// import 'package:dartz/dartz.dart';
// import 'package:client/core/error/failures.dart';
// import '../entities/puzzle.dart';
//
// abstract class PuzzleRepository {
//   /// Get a random puzzle based on user rating and optional theme filter
//   Future<Either<Failure, Puzzle>> getRandomPuzzle({
//     required int userRating,
//     String? theme,
//   });
//
//   /// Get a puzzle by ID
//   Future<Either<Failure, Puzzle>> getPuzzleById(String puzzleId);
//
//   /// Get puzzles by theme
//   Future<Either<Failure, List<Puzzle>>> getPuzzlesByTheme({
//     required String theme,
//     int limit = 20,
//     int offset = 0,
//   });
//
//   /// Submit a puzzle solution
//   Future<Either<Failure, bool>> submitSolution({
//     required String puzzleId,
//     required List<String> moves,
//   });
//
//   /// Get user's puzzle statistics
//   Future<Either<Failure, Map<String, dynamic>>> getUserStats();
//
//   /// Get puzzle themes
//   Future<Either<Failure, List<String>>> getThemes();
// }
