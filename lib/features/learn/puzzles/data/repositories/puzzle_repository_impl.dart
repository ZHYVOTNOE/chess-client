// import 'package:dartz/dartz.dart';
// import 'package:client/core/error/exceptions.dart';
// import 'package:client/core/error/failures.dart';
// import '../../domain/entities/puzzle.dart';
// import '../../domain/repositories/puzzle_repository.dart';
// import '../datasources/puzzle_remote_datasource.dart';
//
// class PuzzleRepositoryImpl implements PuzzleRepository {
//   final PuzzleRemoteDataSource remoteDataSource;
//
//   PuzzleRepositoryImpl(this.remoteDataSource);
//
//   @override
//   Future<Either<Failure, Puzzle>> getRandomPuzzle({
//     required int userRating,
//     String? theme,
//   }) async {
//     try {
//       final puzzle = await remoteDataSource.getRandomPuzzle(
//         userRating: userRating,
//         theme: theme,
//       );
//       return Right(puzzle);
//     } on ServerException {
//       return Left(ServerFailure('Failed to fetch puzzle'));
//     }
//   }
//
//   @override
//   Future<Either<Failure, Puzzle>> getPuzzleById(String puzzleId) async {
//     try {
//       final puzzle = await remoteDataSource.getPuzzleById(puzzleId);
//       return Right(puzzle);
//     } on ServerException {
//       return Left(ServerFailure('Failed to fetch puzzle'));
//     }
//   }
//
//   @override
//   Future<Either<Failure, List<Puzzle>>> getPuzzlesByTheme({
//     required String theme,
//     int limit = 20,
//     int offset = 0,
//   }) async {
//     try {
//       final puzzles = await remoteDataSource.getPuzzlesByTheme(
//         theme: theme,
//         limit: limit,
//         offset: offset,
//       );
//       return Right(puzzles);
//     } on ServerException {
//       return Left(ServerFailure('Failed to fetch puzzles'));
//     }
//   }
//
//   @override
//   Future<Either<Failure, bool>> submitSolution({
//     required String puzzleId,
//     required List<String> moves,
//   }) async {
//     try {
//       final result = await remoteDataSource.submitSolution(
//         puzzleId: puzzleId,
//         moves: moves,
//       );
//       return Right(result);
//     } on ServerException {
//       return Left(ServerFailure('Failed to submit solution'));
//     }
//   }
//
//   @override
//   Future<Either<Failure, Map<String, dynamic>>> getUserStats() async {
//     try {
//       final stats = await remoteDataSource.getUserStats();
//       return Right(stats);
//     } on ServerException {
//       return Left(ServerFailure('Failed to fetch user stats'));
//     }
//   }
//
//   @override
//   Future<Either<Failure, List<String>>> getThemes() async {
//     try {
//       final themes = await remoteDataSource.getThemes();
//       return Right(themes);
//     } on ServerException {
//       return Left(ServerFailure('Failed to fetch themes'));
//     }
//   }
// }
