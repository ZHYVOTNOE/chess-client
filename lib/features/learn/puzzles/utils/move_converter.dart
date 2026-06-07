class MoveConverter {
  /// Converts UCI move format to Standard Algebraic Notation (SAN)
  /// UCI format: "f2g3" (from-to coordinates)
  /// SAN format: "f3", "fxg3", "Bxg3", "e8=Q", "O-O", etc.
  static String uciToSan(String uciMove, String currentFen) {
    // If Bishop accepts UCI directly, return UCI
    // For now, we'll return UCI as-is since Bishop may support it
    return uciMove;
  }

  /// Extracts source square from UCI move
  static String getSourceSquare(String uciMove) {
    if (uciMove.length >= 4) {
      return uciMove.substring(0, 2);
    }
    return '';
  }

  /// Extracts destination square from UCI move
  static String getDestSquare(String uciMove) {
    if (uciMove.length >= 4) {
      return uciMove.substring(2, 4);
    }
    return '';
  }

  /// Checks if move is a promotion
  static bool isPromotion(String uciMove) {
    return uciMove.length == 5;
  }

  /// Gets promotion piece from UCI move
  static String getPromotionPiece(String uciMove) {
    if (isPromotion(uciMove)) {
      return uciMove[4].toUpperCase();
    }
    return '';
  }
}
