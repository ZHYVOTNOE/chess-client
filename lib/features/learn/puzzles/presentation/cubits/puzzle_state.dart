part of 'puzzle_cubit.dart';

abstract class PuzzleState extends Equatable {
  const PuzzleState();
  @override
  List<Object?> get props => [];
}

class PuzzleInitial extends PuzzleState {}
class PuzzleLoading extends PuzzleState {}

class PuzzleLoaded extends PuzzleState {
  final String fen;
  final int currentMoveIndex;
  final bool isOpponentTurn;
  final String userColor;
  final bool isHintShown;
  final int streak;
  final int solvedToday;
  final int userRating;
  final int elapsedSeconds;
  final String? feedbackMessage;
  final int? ratingDelta;
  final int hintLevel; // 0=нет, 1=фигура подсвечена, 2=стрелка

  const PuzzleLoaded({
    required this.fen,
    required this.currentMoveIndex,
    required this.isOpponentTurn,
    required this.userColor,
    this.isHintShown = false,
    this.streak = 0,
    this.solvedToday = 0,
    this.userRating = 1500,
    this.elapsedSeconds = 0,
    this.feedbackMessage,
    this.ratingDelta,
    this.hintLevel = 0,
  });

  PuzzleLoaded copyWith({
    String? fen,
    int? currentMoveIndex,
    bool? isOpponentTurn,
    String? userColor,
    bool? isHintShown,
    int? streak,
    int? solvedToday,
    int? userRating,
    int? elapsedSeconds,
    Object? feedbackMessage = _sentinel,
    Object? ratingDelta = _sentinel,
    int? hintLevel,
  }) {
    return PuzzleLoaded(
      fen: fen ?? this.fen,
      currentMoveIndex: currentMoveIndex ?? this.currentMoveIndex,
      isOpponentTurn: isOpponentTurn ?? this.isOpponentTurn,
      userColor: userColor ?? this.userColor,
      isHintShown: isHintShown ?? this.isHintShown,
      streak: streak ?? this.streak,
      solvedToday: solvedToday ?? this.solvedToday,
      userRating: userRating ?? this.userRating,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      feedbackMessage: feedbackMessage == _sentinel ? this.feedbackMessage : feedbackMessage as String?,
      ratingDelta: ratingDelta == _sentinel ? this.ratingDelta : ratingDelta as int?,
      hintLevel: hintLevel ?? this.hintLevel,
    );
  }

  @override
  List<Object?> get props => [
    fen, currentMoveIndex, isOpponentTurn, userColor, isHintShown,
    streak, solvedToday, userRating, elapsedSeconds,
    feedbackMessage, ratingDelta, hintLevel,
  ];
}

const _sentinel = Object();

class PuzzleSolved extends PuzzleState {
  final String fen;
  final int currentMoveIndex;
  final String userColor;
  final int streak;
  final int solvedToday;
  final int userRating;
  final int elapsedSeconds;
  final int? ratingDelta;

  const PuzzleSolved({
    required this.fen,
    required this.currentMoveIndex,
    required this.userColor,
    this.streak = 0,
    this.solvedToday = 0,
    this.userRating = 1500,
    this.elapsedSeconds = 0,
    this.ratingDelta,
  });

  @override
  List<Object?> get props => [
    fen, currentMoveIndex, userColor,
    streak, solvedToday, userRating, elapsedSeconds, ratingDelta,
  ];
}

class PuzzleError extends PuzzleState {
  final String message;
  const PuzzleError({required this.message});
  @override
  List<Object?> get props => [message];
}