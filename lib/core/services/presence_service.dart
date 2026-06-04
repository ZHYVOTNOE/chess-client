import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PresenceService with WidgetsBindingObserver {
  Timer? _heartbeatTimer;
  String? _userId;

  static const Duration _heartbeatInterval = Duration(seconds: 30);
  static const int _onlineThresholdMinutes = 2;

  void init(String userId) {
    print('🟢 [PresenceService] init() called for user: $userId');

    if (_userId == userId) {
      print('🟡 [PresenceService] Already initialized for this user, skipping');
      return;
    }

    _userId = userId;
    WidgetsBinding.instance.addObserver(this);
    _startHeartbeat();
    print('✅ [PresenceService] Heartbeat started');
  }

  void dispose() {
    print('🔴 [PresenceService] dispose() called');
    WidgetsBinding.instance.removeObserver(this);
    _stopHeartbeat();
    _userId = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('🔄 [PresenceService] App lifecycle: $state');
    if (_userId == null) return;

    switch (state) {
      case AppLifecycleState.resumed:
        _startHeartbeat();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _stopHeartbeat();
        break;
    }
  }

  void _startHeartbeat() {
    _sendPing();
    _heartbeatTimer ??= Timer.periodic(_heartbeatInterval, (_) => _sendPing());
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  Future<void> _sendPing() async {
    if (_userId == null) {
      print('❌ [PresenceService] Cannot ping: _userId is null');
      return;
    }

    try {
      final timestamp = DateTime.now().toUtc().toIso8601String();
      print('📡 [PresenceService] Sending ping for $_userId at $timestamp');

      await Supabase.instance.client.from('profiles').upsert({
        'id': _userId,
        'last_seen_at': timestamp,
      });

      print('✅ [PresenceService] Ping successful');
    } catch (e) {
      print('❌ [PresenceService] Ping failed: $e');
    }
  }

  static bool isOnline(DateTime? lastSeenAt) {
    if (lastSeenAt == null) return false;
    return DateTime.now().difference(lastSeenAt).inMinutes < _onlineThresholdMinutes;
  }

  static String formatLastSeen(DateTime? lastSeenAt) {
    if (lastSeenAt == null) return 'Не в сети';

    final now = DateTime.now();
    final diff = now.difference(lastSeenAt);

    if (diff.inMinutes < _onlineThresholdMinutes) {
      return 'Онлайн';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} мин назад';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} ч назад';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} дн назад';
    } else {
      return 'давно';
    }
  }
}