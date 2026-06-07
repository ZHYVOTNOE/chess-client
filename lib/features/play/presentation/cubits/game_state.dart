import 'package:equatable/equatable.dart';
import 'package:square_bishop/square_bishop.dart';
import 'package:squares/squares.dart';

class PlayGameState extends Equatable {
  final SquaresState squaresState;
  final String? fen;
  final Duration whiteTime;
  final Duration blackTime;
  final bool isBotThinking;
  final bool isGameOver;
  final String? result;
  final Move? premove;
  final bool isFlipped;
  final bool isReviewing;
  final int historyIndex;
  final int historyLength;
  final List<String> moveSan;

  const PlayGameState({
    required this.squaresState,
    this.fen,
    this.whiteTime = Duration.zero,
    this.blackTime = Duration.zero,
    this.isBotThinking = false,
    this.isGameOver = false,
    this.result,
    this.premove,
    this.isFlipped = false,
    this.isReviewing = false,
    this.historyIndex = -1,
    this.historyLength = 0,
    this.moveSan = const [],
  });

  PlayGameState copyWith({
    SquaresState? squaresState,
    String? fen,
    Duration? whiteTime,
    Duration? blackTime,
    bool? isBotThinking,
    bool? isGameOver,
    String? result,
    Move? premove,
    bool? isFlipped,
    bool? isReviewing,
    int? historyIndex,
    int? historyLength,
    List<String>? moveSan,
  }) {
    return PlayGameState(
      squaresState: squaresState ?? this.squaresState,
      fen: fen ?? this.fen,
      whiteTime: whiteTime ?? this.whiteTime,
      blackTime: blackTime ?? this.blackTime,
      isBotThinking: isBotThinking ?? this.isBotThinking,
      isGameOver: isGameOver ?? this.isGameOver,
      result: result ?? this.result,
      premove: premove ?? this.premove,
      isFlipped: isFlipped ?? this.isFlipped,
      isReviewing: isReviewing ?? this.isReviewing,
      historyIndex: historyIndex ?? this.historyIndex,
      historyLength: historyLength ?? this.historyLength,
      moveSan: moveSan ?? this.moveSan,
    );
  }

  PlayGameState clearPremove() {
    return copyWith(premove: null);
  }

  bool get canStepBack => isReviewing && historyIndex > 0;

  bool get canStepForward => isReviewing && historyIndex < historyLength - 1;

  @override
  List<Object?> get props => [
        squaresState,
        fen,
        whiteTime,
        blackTime,
        isBotThinking,
        isGameOver,
        result,
        premove,
        isFlipped,
        isReviewing,
        historyIndex,
        historyLength,
        moveSan,
      ];
}