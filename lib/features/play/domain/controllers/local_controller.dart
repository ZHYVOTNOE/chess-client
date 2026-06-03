import 'dart:async';
import 'package:squares/squares.dart';
import 'game_controller.dart';

class LocalController implements GameController {
  bool _isThinking = false;
  final _thinkingController = StreamController<bool>.broadcast();

  @override
  bool get isOpponentThinking => _isThinking;

  @override
  Stream<bool> get opponentThinkingStream => _thinkingController.stream;

  @override
  Future<void> makeMove(Move move, String fen) async {
    // Local play - moves are handled by GameEngine
    // No network sync needed
  }

  @override
  Future<Move?> getOpponentMove(String fen) async {
    // Local play - opponent is the other player on the same device
    // No AI calculation needed
    return null;
  }

  @override
  Future<void> resign() async {
    // Local play - resign is handled by GameEngine
  }

  @override
  Future<void> offerDraw() async {
    // Local play - draw offers are handled by GameEngine
  }

  @override
  void dispose() {
    _thinkingController.close();
  }
}
