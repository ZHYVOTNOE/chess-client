import 'package:squares/squares.dart';
import 'custom_piece_set.dart';

class PieceSetLoader {
  static PieceSet load(String setId) {
    return CustomPieceSet.fromSvgAssets(
      folder: 'assets/pieces/$setId/',
      symbols: PieceSet.defaultSymbols,
    );
  }
}