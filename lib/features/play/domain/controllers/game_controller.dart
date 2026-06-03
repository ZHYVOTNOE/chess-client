import 'dart:async';
import 'package:squares/squares.dart';

/// Strategy pattern interface for different game modes
abstract class GameController {
  /// Make a move in the game
  Future<void> makeMove(Move move, String fen);

  /// Get opponent's move (for bot or online sync)
  Future<Move?> getOpponentMove(String fen);

  /// Resign from the game
  Future<void> resign();

  /// Offer a draw
  Future<void> offerDraw();

  /// Check if the opponent is currently thinking (for bot or network delay)
  bool get isOpponentThinking;

  /// Stream of opponent thinking state changes
  Stream<bool> get opponentThinkingStream;

  /// Dispose resources
  void dispose();
}
