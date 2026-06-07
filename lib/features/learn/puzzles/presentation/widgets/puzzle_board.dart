import 'package:flutter/material.dart';
import 'package:squares/squares.dart';
import 'package:square_bishop/square_bishop.dart';
import 'package:bishop/bishop.dart' as bishop;
import 'package:client/core/utils/piece_set_loader.dart';

class PuzzleBoard extends StatelessWidget {
  final String fen;
  final String userColor;
  final bool isOpponentTurn;
  final bool isHintShown;
  final Function(String) onMoveMade;

  const PuzzleBoard({
    super.key,
    required this.fen,
    required this.userColor,
    required this.isOpponentTurn,
    required this.isHintShown,
    required this.onMoveMade,
  });

  @override
  Widget build(BuildContext context) {
    try {
      final game = bishop.Game(fen: fen);
      final playerIndex = userColor == 'white' ? 0 : 1;
      final squaresState = game.squaresState(playerIndex);

      return Center(
        child: AspectRatio(
          aspectRatio: squaresState.size.aspectRatio,
          child: BoardController(
            state: squaresState.board,
            playState: isOpponentTurn
                ? PlayState.theirTurn
                : squaresState.state,
            size: squaresState.size,
            pieceSet: PieceSetLoader.load('merida'),
            theme: BoardTheme.brown,
            moves: isOpponentTurn ? const [] : squaresState.moves,
            onMove: isOpponentTurn
                ? null
                : (move) {
              print('=== RAW move.from: ${move.from}, move.to: ${move.to}');
              print('=== move.runtimeType: ${move.runtimeType}');
              print('=== squaresState.size.h: ${squaresState.size.h}');

              // Попытка 1: algebraic()
              try {
                final uci = move.algebraic(squaresState.size);
                print('=== algebraic() uci: $uci');
                onMoveMade(uci);
                return;
              } catch (e) {
                print('=== algebraic() failed: $e');
              }

              // Попытка 2: ручная конвертация без учёта ориентации
              final h = squaresState.size.h.toInt();
              String toAlg(int idx) {
                final file = String.fromCharCode('a'.codeUnitAt(0) + (idx % h));
                final rank = (idx ~/ h + 1).toString();
                return '$file$rank';
              }
              final uci = '${toAlg(move.from)}${toAlg(move.to)}';
              print('=== manual uci: $uci');
              onMoveMade(uci);
            },
            markerTheme: MarkerTheme(
              empty: MarkerTheme.dot,
              piece: MarkerTheme.corners(),
            ),
            promotionBehaviour: PromotionBehaviour.autoPremove,
          ),
        ),
      );
    } catch (e) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading board: $e'),
          ],
        ),
      );
    }
  }
}