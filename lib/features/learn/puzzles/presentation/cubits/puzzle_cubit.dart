// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:equatable/equatable.dart';
// import 'package:client/core/error/failures.dart';
// import 'package:client/core/providers/locale_provider.dart';
// import '../../domain/entities/puzzle.dart';
// import '../../domain/usecases/get_random_puzzle.dart';
// import '../../domain/usecases/get_puzzle_themes.dart';
// import '../../domain/usecases/submit_solution.dart';
// import '../../domain/usecases/get_user_stats.dart';
//
// part 'puzzle_state.dart';
//
// class PuzzleCubit extends Cubit<PuzzleState> {
//   final GetRandomPuzzle getRandomPuzzle;
//   final GetPuzzleThemes getThemes;
//   final SubmitSolution submitSolution;
//   final GetUserStats getUserStats;
//   final LocaleProvider locale;
//
//   PuzzleCubit({
//     required this.getRandomPuzzle,
//     required this.getThemes,
//     required this.submitSolution,
//     required this.getUserStats,
//     required this.locale,
//   }) : super(PuzzleInitial()) {
//     loadThemes();
//   }
//
//   int _userRating = 1500;
//   String _selectedTheme = 'all';
//   List<String> _userMoves = [];
//   int _currentMoveIndex = 0;
//
//   Future<void> loadThemes() async {
//     emit(PuzzleLoading());
//     final themesResult = await getThemes();
//     final statsResult = await getUserStats();
//
//     themesResult.fold(
//       (failure) => emit(PuzzleError(message: _mapFailureToMessage(failure))),
//       (themes) {
//         statsResult.fold(
//           (failure) => emit(PuzzleThemesLoaded(themes: themes)),
//           (stats) {
//             final streak = stats['streak'] as int? ?? 0;
//             final solvedToday = stats['solved_today'] as int? ?? 0;
//             final progress = 0; // Calculate progress based on rating changes
//             emit(PuzzleThemesLoaded(
//               themes: themes,
//               streak: streak,
//               solvedToday: solvedToday,
//               progress: progress,
//             ));
//           },
//         );
//       },
//     );
//   }
//
//   Future<void> loadRandomPuzzle() async {
//     emit(PuzzleLoading());
//     final result = await getRandomPuzzle(
//       userRating: _userRating,
//       theme: _selectedTheme,
//     );
//
//     result.fold(
//       (failure) => emit(PuzzleError(message: _mapFailureToMessage(failure))),
//       (puzzle) {
//         _userMoves = [];
//         _currentMoveIndex = 0;
//         emit(PuzzleLoaded(
//           puzzle: puzzle,
//           userMoves: [],
//           currentMoveIndex: 0,
//           isCorrect: null,
//         ));
//       },
//     );
//   }
//
//   void selectTheme(String theme) {
//     _selectedTheme = theme;
//     loadRandomPuzzle();
//   }
//
//   void setUserRating(int rating) {
//     _userRating = rating;
//   }
//
//   void makeMove(String move) {
//     if (state is! PuzzleLoaded) return;
//
//     final currentState = state as PuzzleLoaded;
//     final puzzle = currentState.puzzle;
//
//     if (_currentMoveIndex >= puzzle.moves.length) return;
//
//     final expectedMove = puzzle.moves[_currentMoveIndex];
//     final isCorrect = move == expectedMove;
//
//     _userMoves.add(move);
//     _currentMoveIndex++;
//
//     if (isCorrect) {
//       if (_currentMoveIndex == puzzle.moves.length) {
//         // All moves correct - puzzle solved
//         emit(PuzzleSolved(
//           puzzle: puzzle,
//           userMoves: List.from(_userMoves),
//           currentMoveIndex: _currentMoveIndex,
//         ));
//       } else {
//         emit(PuzzleLoaded(
//           puzzle: puzzle,
//           userMoves: List.from(_userMoves),
//           currentMoveIndex: _currentMoveIndex,
//           isCorrect: true,
//         ));
//       }
//     } else {
//       // Wrong move
//       emit(PuzzleFailed(
//         puzzle: puzzle,
//         userMoves: List.from(_userMoves),
//         currentMoveIndex: _currentMoveIndex,
//       ));
//     }
//   }
//
//   void resetPuzzle() {
//     _userMoves = [];
//     _currentMoveIndex = 0;
//     if (state is PuzzleLoaded) {
//       final currentState = state as PuzzleLoaded;
//       emit(PuzzleLoaded(
//         puzzle: currentState.puzzle,
//         userMoves: [],
//         currentMoveIndex: 0,
//         isCorrect: null,
//       ));
//     } else if (state is PuzzleFailed) {
//       final currentState = state as PuzzleFailed;
//       emit(PuzzleLoaded(
//         puzzle: currentState.puzzle,
//         userMoves: [],
//         currentMoveIndex: 0,
//         isCorrect: null,
//       ));
//     }
//   }
//
//   void skipPuzzle() {
//     loadRandomPuzzle();
//   }
//
//   String _mapFailureToMessage(Failure failure) {
//     if (failure is ServerFailure) {
//       return locale.get('puzzles_error_server');
//     }
//     return locale.get('puzzles_error_unexpected');
//   }
// }
