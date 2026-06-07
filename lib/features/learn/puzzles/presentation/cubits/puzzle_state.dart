// part of 'puzzle_cubit.dart';
//
// abstract class PuzzleState extends Equatable {
//   const PuzzleState();
//
//   @override
//   List<Object?> get props => [];
// }
//
// class PuzzleInitial extends PuzzleState {}
//
// class PuzzleLoading extends PuzzleState {}
//
// class PuzzleThemesLoaded extends PuzzleState {
//   final List<String> themes;
//   final int streak;
//   final int solvedToday;
//   final int progress;
//
//   const PuzzleThemesLoaded({
//     required this.themes,
//     this.streak = 0,
//     this.solvedToday = 0,
//     this.progress = 0,
//   });
//
//   @override
//   List<Object?> get props => [themes, streak, solvedToday, progress];
// }
//
// class PuzzleLoaded extends PuzzleState {
//   final Puzzle puzzle;
//   final List<String> userMoves;
//   final int currentMoveIndex;
//   final bool? isCorrect;
//
//   const PuzzleLoaded({
//     required this.puzzle,
//     required this.userMoves,
//     required this.currentMoveIndex,
//     this.isCorrect,
//   });
//
//   @override
//   List<Object?> get props => [puzzle, userMoves, currentMoveIndex, isCorrect];
// }
//
// class PuzzleSolved extends PuzzleState {
//   final Puzzle puzzle;
//   final List<String> userMoves;
//   final int currentMoveIndex;
//
//   const PuzzleSolved({
//     required this.puzzle,
//     required this.userMoves,
//     required this.currentMoveIndex,
//   });
//
//   @override
//   List<Object?> get props => [puzzle, userMoves, currentMoveIndex];
// }
//
// class PuzzleFailed extends PuzzleState {
//   final Puzzle puzzle;
//   final List<String> userMoves;
//   final int currentMoveIndex;
//
//   const PuzzleFailed({
//     required this.puzzle,
//     required this.userMoves,
//     required this.currentMoveIndex,
//   });
//
//   @override
//   List<Object?> get props => [puzzle, userMoves, currentMoveIndex];
// }
//
// class PuzzleError extends PuzzleState {
//   final String message;
//
//   const PuzzleError({required this.message});
//
//   @override
//   List<Object?> get props => [message];
// }
