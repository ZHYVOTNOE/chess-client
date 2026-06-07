// import 'package:flutter/material.dart';
// import 'package:squares/squares.dart';
// import 'package:square_bishop/square_bishop.dart';
// import 'package:bishop/bishop.dart' as bishop;
// import 'package:client/core/utils/piece_set_loader.dart';
// import '../../domain/entities/puzzle.dart';
//
// class PuzzleBoard extends StatelessWidget {
//   final Puzzle puzzle;
//   final List<String> userMoves;
//   final Function(String) onMoveMade;
//
//   const PuzzleBoard({
//     super.key,
//     required this.puzzle,
//     required this.userMoves,
//     required this.onMoveMade,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     try {
//       debugPrint('PuzzleBoard: Loading puzzle with FEN: ${puzzle.fen}');
//       final game = bishop.Game(fen: puzzle.fen);
//       debugPrint('PuzzleBoard: Game created successfully');
//       final squaresState = game.squaresState(0);
//       debugPrint('PuzzleBoard: SquaresState created');
//
//       return Center(
//         child: AspectRatio(
//           aspectRatio: squaresState.size.aspectRatio,
//           child: BoardController(
//             state: squaresState.board,
//             playState: squaresState.state,
//             size: squaresState.size,
//             pieceSet: PieceSetLoader.load('merida', rotateBlackPieces: false),
//             theme: BoardTheme.brown,
//             moves: squaresState.moves,
//             onMove: (move) {
//               final uci = '${move.from}${move.to}';
//               onMoveMade(uci);
//             },
//             markerTheme: MarkerTheme(
//               empty: MarkerTheme.dot,
//               piece: MarkerTheme.corners(),
//             ),
//             promotionBehaviour: PromotionBehaviour.autoPremove,
//           ),
//         ),
//       );
//     } catch (e) {
//       debugPrint('PuzzleBoard error: $e');
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(Icons.error_outline, size: 48, color: Colors.red),
//             const SizedBox(height: 16),
//             Text('Error loading board: $e'),
//           ],
//         ),
//       );
//     }
//   }
// }
