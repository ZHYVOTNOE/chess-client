import 'package:squares/squares.dart';
import 'custom_piece_set.dart';

class PieceSetLoader {
  static PieceSet load(String setId) {
    if (!['merida', 'staunty', 'alpha', 'pixel', 'letter'].contains(setId)) {
      return PieceSet.merida();
    }

    return CustomPieceSet.fromSvgAssets(
      folder: 'assets/pieces/$setId/',
      symbols: PieceSet.defaultSymbols,
    );
  }
}