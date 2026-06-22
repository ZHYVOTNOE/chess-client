import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:squares/squares.dart';
import 'package:square_bishop/square_bishop.dart';
import 'package:bishop/bishop.dart' as bishop;
import 'package:client/core/utils/piece_set_loader.dart';
import 'package:client/core/providers/settings_provider.dart';
import 'package:client/core/providers/locale_provider.dart';
import 'package:client/core/providers/user_provider.dart';
import 'package:client/features/settings/constants/custom_board_themes.dart';

class PuzzleBoard extends StatelessWidget {
  final String fen;
  final String userColor;
  final bool isOpponentTurn;
  final bool isHintShown;
  final int hintLevel;
  final String? hintMove;
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

  int _algToIndex(String sq, BoardSize size) {
    final file = sq.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final rank = int.parse(sq[1]) - 1;
    return rank * size.h.toInt() + file;
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    // Load settings if not loaded
    if (settings.settings == null && !settings.isLoading) {
      final userId = context.read<UserProvider>().userId;
      if (userId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<SettingsProvider>().loadSettings(userId);
        });
      }
      // Show loading while settings are being loaded
      return const Center(child: CircularProgressIndicator());
    }
    
    // Show loading if settings are currently loading
    if (settings.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final pieceSet = settings.settings?.pieceSet ?? 'merida';
    final boardTheme = CustomBoardThemes.all
        .firstWhere(
          (e) => e.id == settings.settings?.boardTheme,
      orElse: () => CustomBoardThemes.all[0],
    )
        .theme;

    try {
      final game = bishop.Game(fen: fen);
      final playerIndex = userColor == 'white' ? 0 : 1;
      final squaresState = game.squaresState(playerIndex);

      // Подсветка фигуры (hintLevel >= 1)
      List<Widget> underlays = [];
      if (hintLevel >= 1 && hintMove != null && hintMove!.length >= 4) {
        final fromSq = hintMove!.substring(0, 2);
        final fromIdx = _algToIndex(fromSq, squaresState.size);
        underlays = [
          _SquareHighlight(
            square: fromIdx,
            size: squaresState.size,
            color: Colors.yellow.withValues(alpha: 0.7),
          ),
        ];
      }

      // Стрелка (hintLevel >= 2)
      List<Widget> overlays = [];
      if (hintLevel >= 2 && hintMove != null && hintMove!.length >= 4) {
        overlays = [
          _HintArrow(
            fromSq: hintMove!.substring(0, 2),
            toSq: hintMove!.substring(2, 4),
            playerIndex: playerIndex,
            size: squaresState.size,
          ),
        ];
      }

      return Center(
        child: AspectRatio(
          aspectRatio: squaresState.size.aspectRatio,
          child: BoardController(
            state: squaresState.board,
            playState: isOpponentTurn || hintLevel >= 2
                ? PlayState.theirTurn
                : squaresState.state,
            size: squaresState.size,
            pieceSet: PieceSetLoader.load(pieceSet),
            theme: boardTheme,
            moves: (isOpponentTurn || hintLevel >= 2) ? const [] : squaresState.moves,
            animatePieces: true,
            animationDuration: const Duration(milliseconds: 250),
            animationCurve: Curves.easeInOut,
            onMove: (isOpponentTurn || hintLevel >= 2)
                ? null
                : (move) {
              try {
                final uci = move.algebraic(squaresState.size);
                onMoveMade(uci);
              } catch (_) {
                final h = squaresState.size.h.toInt();
                String toAlg(int idx) {
                  final file = String.fromCharCode(
                      'a'.codeUnitAt(0) + (idx % h));
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
            underlays: underlays,
            overlays: overlays,
          ),
        ),
      );
    } catch (e) {
      final locale = context.read<LocaleProvider>();
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('${locale.get('puzzles_board_error')}$e'),
          ],
        ),
      );
    }
  }
}

class _SquareHighlight extends StatelessWidget {
  final int square;
  final BoardSize size;
  final Color color;

  const _SquareHighlight({
    required this.square,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final sqW = constraints.maxWidth / size.h;
          final sqH = constraints.maxHeight / size.v;
          final file = square % size.h.toInt();
          final rank = square ~/ size.h.toInt();
          // Squares рисует с 8й горизонтали вверху
          final x = file * sqW;
          final y = (size.v.toInt() - 1 - rank) * sqH;

          return Stack(
            children: [
              Positioned(
                left: x,
                top: y,
                width: sqW,
                height: sqH,
                child: Container(color: color),
              ),
            ],
          );
        },
      ),
    );
  }
}

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
      child: IgnorePointer(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final canvasSize =
            Size(constraints.maxWidth, constraints.maxHeight);
            final from = _squareCenter(fromSq, canvasSize);
            final to = _squareCenter(toSq, canvasSize);
            return CustomPaint(
              painter: _ArrowPainter(from: from, to: to),
            );
          },
        ),
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
    final dir = to - from;
    final dist = dir.distance;
    if (dist == 0) return;

    final norm = dir / dist;
    final perp = Offset(-norm.dy, norm.dx);
    const strokeW = 10.0;
    const arrowHead = 24.0;

    // Линия чуть не доходит до центра клетки назначения
    final lineEnd = to - norm * (arrowHead * 0.6);

    final paint = Paint()
      ..color = Colors.yellow.withValues(alpha: 0.85)
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(from, lineEnd, paint);

    // Наконечник
    final tip = to;
    final base1 = lineEnd + perp * arrowHead * 0.6;
    final base2 = lineEnd - perp * arrowHead * 0.6;

    final arrowPath = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(base1.dx, base1.dy)
      ..lineTo(base2.dx, base2.dy)
      ..close();

    canvas.drawPath(
      arrowPath,
      Paint()
        ..color = Colors.yellow.withValues(alpha: 0.85)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter old) =>
      old.from != from || old.to != to;
}