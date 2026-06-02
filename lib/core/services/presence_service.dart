import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class PresenceService {
  Timer? _heartbeatTimer;
  static const Duration _heartbeatInterval = Duration(minutes: 2);

  void startHeartbeat(String userId) {
    stopHeartbeat();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) async {
      await _updateLastSeen(userId);
    });
  }

  void stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  Future<void> _updateLastSeen(String userId) async {
    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'last_seen_at': DateTime.now().toIso8601String()})
          .eq('id', userId);
    } catch (e) {
      // Silently fail to avoid disrupting the app
      print('Failed to update last_seen_at: $e');
    }
  }

  void dispose() {
    stopHeartbeat();
  }
}
