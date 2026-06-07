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
  final int hintLevel;
  final String? hintMove; // UCI формат e.g. "e2e4"
  final Function(String) onMoveMade;

  const PuzzleBoard({
    super.key,
    required this.fen,
    required this.userColor,
    required this.isOpponentTurn,
    required this.isHintShown,
    required this.onMoveMade,
    this.hintLevel = 0,
    this.hintMove,
  });

  // Конвертируем UCI квадрат ("e2") в индекс squares с учётом ориентации
  int _squareToIndex(String sq, int playerIndex, BoardSize size) {
    final file = sq.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final rank = int.parse(sq[1]) - 1;
    final rawIndex = rank * size.h.toInt() + file;
    return rawIndex;
  }

  @override
  Widget build(BuildContext context) {
    try {
      final game = bishop.Game(fen: fen);
      final playerIndex = userColor == 'white' ? 0 : 1;
      final squaresState = game.squaresState(playerIndex);

      // Парсим hintMove для подсветки
      List<int> hintSquares = [];
      if (hintMove != null && hintMove!.length >= 4 && hintLevel > 0) {
        final fromSq = hintMove!.substring(0, 2);
        final toSq = hintMove!.substring(2, 4);
        final fromIdx = _squareToIndex(fromSq, playerIndex, squaresState.size);
        if (hintLevel == 1) {
          hintSquares = [fromIdx]; // только фигура
        } else {
          hintSquares = [fromIdx, _squareToIndex(toSq, playerIndex, squaresState.size)];
        }
      }

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
            animatePieces: true,
            animationDuration: const Duration(milliseconds: 250),
            animationCurve: Curves.easeInOut,
            onMove: isOpponentTurn
                ? null
                : (move) {
              try {
                final uci = move.algebraic(squaresState.size);
                onMoveMade(uci);
              } catch (_) {
                final h = squaresState.size.h.toInt();
                String toAlg(int idx) {
                  final file = String.fromCharCode('a'.codeUnitAt(0) + (idx % h));
                  final rank = (idx ~/ h + 1).toString();
                  return '$file$rank';
                }
                onMoveMade('${toAlg(move.from)}${toAlg(move.to)}');
              }
            },
            markerTheme: MarkerTheme(
              empty: MarkerTheme.dot,
              piece: MarkerTheme.corners(),
            ),
            promotionBehaviour: PromotionBehaviour.autoPremove,
            underlays: hintSquares.isNotEmpty
                ? hintSquares.map((sq) => SquareHighlight(
              square: sq,
              color: Colors.yellow.withValues(alpha: 0.6),
            )).toList()
                : [],
            overlays: hintLevel == 2 && hintMove != null && hintMove!.length >= 4
                ? [
              _HintArrow(
                fromSq: hintMove!.substring(0, 2),
                toSq: hintMove!.substring(2, 4),
                playerIndex: playerIndex,
                size: squaresState.size,
              ),
            ]
                : [],
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

// Подсветка квадрата
class SquareHighlight extends StatelessWidget {
  final int square;
  final Color color;

  const SquareHighlight({super.key, required this.square, required this.color});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

// Стрелка подсказки
class _HintArrow extends StatelessWidget {
  final String fromSq;
  final String toSq;
  final int playerIndex;
  final BoardSize size;

  const _HintArrow({
    required this.fromSq,
    required this.toSq,
    required this.playerIndex,
    required this.size,
  });

  Offset _squareCenter(String sq, Size canvasSize) {
    final file = sq.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final rank = int.parse(sq[1]) - 1;
    final sqW = canvasSize.width / size.h;
    final sqH = canvasSize.height / size.v;

    final displayFile = playerIndex == 0 ? file : (size.h.toInt() - 1 - file);
    final displayRank = playerIndex == 0
        ? (size.v.toInt() - 1 - rank)
        : rank;

    return Offset(
      displayFile * sqW + sqW / 2,
      displayRank * sqH + sqH / 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
          final from = _squareCenter(fromSq, canvasSize);
          final to = _squareCenter(toSq, canvasSize);

          return CustomPaint(
            painter: _ArrowPainter(from: from, to: to),
          );
        },
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  final Offset from;
  final Offset to;

  _ArrowPainter({required this.from, required this.to});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.yellow.withValues(alpha: 0.85)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(from, to, paint);

    // Наконечник стрелки
    final angle = (to - from).direction;
    const arrowSize = 20.0;
    final path = Path();
    path.moveTo(to.dx, to.dy);
    path.lineTo(
      to.dx - arrowSize * (0.866 * (to - from).dx / (to - from).distance +
          0.5 * (to - from).dy / (to - from).distance),
      to.dy - arrowSize * (0.866 * (to - from).dy / (to - from).distance -
          0.5 * (to - from).dx / (to - from).distance),
    );
    path.lineTo(
      to.dx - arrowSize * (0.866 * (to - from).dx / (to - from).distance -
          0.5 * (to - from).dy / (to - from).distance),
      to.dy - arrowSize * (0.866 * (to - from).dy / (to - from).distance +
          0.5 * (to - from).dx / (to - from).distance),
    );
    path.close();

    canvas.drawPath(path, paint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter old) =>
      old.from != from || old.to != to;
}