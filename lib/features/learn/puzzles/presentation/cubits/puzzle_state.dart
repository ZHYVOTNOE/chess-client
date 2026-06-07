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
  final int ratingProgress;

  const PuzzleLoaded({
    required this.fen,
    required this.currentMoveIndex,
    required this.isOpponentTurn,
    required this.userColor,
    this.isHintShown = false,
    this.streak = 0,
    this.solvedToday = 0,
    this.ratingProgress = 0,
  });

  PuzzleLoaded copyWith({
    String? fen,
    int? currentMoveIndex,
    bool? isOpponentTurn,
    String? userColor,
    bool? isHintShown,
    int? streak,
    int? solvedToday,
    int? ratingProgress,
  }) {
    return PuzzleLoaded(
      fen: fen ?? this.fen,
      currentMoveIndex: currentMoveIndex ?? this.currentMoveIndex,
      isOpponentTurn: isOpponentTurn ?? this.isOpponentTurn,
      userColor: userColor ?? this.userColor,
      isHintShown: isHintShown ?? this.isHintShown,
      streak: streak ?? this.streak,
      solvedToday: solvedToday ?? this.solvedToday,
      ratingProgress: ratingProgress ?? this.ratingProgress,
    );
  }

  @override
  List<Object?> get props => [
    fen,
    currentMoveIndex,
    isOpponentTurn,
    userColor,
    isHintShown,
    streak,
    solvedToday,
    ratingProgress,
  ];
}

class PuzzleSolved extends PuzzleState {
  final String fen;
  final int currentMoveIndex;
  final String userColor;
  final int streak;
  final int solvedToday;
  final int ratingProgress;

  const PuzzleSolved({
    required this.fen,
    required this.currentMoveIndex,
    required this.userColor,
    this.streak = 0,
    this.solvedToday = 0,
    this.ratingProgress = 0,
  });

  @override
  List<Object?> get props => [
    fen,
    currentMoveIndex,
    userColor,
    streak,
    solvedToday,
    ratingProgress,
  ];
}

class PuzzleError extends PuzzleState {
  final String message;

  const PuzzleError({required this.message});

  @override
  List<Object?> get props => [message];
}