import 'package:supabase_flutter/supabase_flutter.dart';

/// Utility for determining board orientation based on player color
class BoardOrientation {
  /// Determines if the current user is playing as white
  /// Returns true if auth.uid == white_id, false if auth.uid == black_id
  static bool isUserWhite({
    required String? whiteId,
    required String? blackId,
  }) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return true; // Default to white if not authenticated

    return currentUserId == whiteId;
  }

  /// Determines if the board should be flipped for the current user
  /// Board should be flipped if user is playing as black (black pieces at bottom)
  static bool shouldFlipBoard({
    required String? whiteId,
    required String? blackId,
  }) {
    return !isUserWhite(whiteId: whiteId, blackId: blackId);
  }

  /// Gets the opponent's ID
  static String? getOpponentId({
    required String? whiteId,
    required String? blackId,
  }) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return blackId;

    return currentUserId == whiteId ? blackId : whiteId;
  }
}
