import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class MatchmakingWebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  final String serverUrl;

  MatchmakingWebSocketService({required this.serverUrl});

  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  Future<void> connect(String jwtToken, {String? userId}) async {
    // Защита от повторного подключения
    if (_channel != null) {
      print('⚠️ [WS] Already connected. Ignoring duplicate request.');
      return;
    }

    try {
      print('🔌 [WS] Connecting to $serverUrl...');
      _channel = WebSocketChannel.connect(Uri.parse(serverUrl));
      await _channel!.ready;
      print('✅ [WS] Connected successfully');

      _subscription = _channel!.stream.listen(
            (message) {
          print('📨 [WS] Received: $message');
          final data = jsonDecode(message as String) as Map<String, dynamic>;

          // Игнорируем пинги
          if (data['action'] == 'ping') return;

          _messageController.add(data);
        },
        onError: (error) {
          print('❌ [WS] Stream error: $error');
          _channel = null;
          _messageController.add({'error': 'WebSocket error: $error'});
        },
        onDone: () {
          print('🔌 [WS] Connection closed');
          _channel = null;
          _messageController.add({'error': 'WebSocket connection closed'});
        },
      );

      print('📤 [WS] Sending authenticate...');
      _channel!.sink.add(jsonEncode({
        'action': 'authenticate',
        'token': jwtToken,
        if (userId != null) 'user_id': userId,
      }));

    } catch (e) {
      print('❌ [WS] Connection failed: $e');
      _channel = null;
      _messageController.add({'error': 'Failed to connect: $e'});
    }
  }

  Future<void> findMatch({
    required String variant,
    required String timeControlType,
    required String timeControl,
    required int rating,
    required int ratingRange,
  }) async {
    if (_channel == null) {
      print('❌ [WS] findMatch called but channel is null');
      _messageController.add({'error': 'Not connected to server'});
      return;
    }

    print('🔍 [WS] Sending find_match: variant=$variant, rating=$rating');
    _channel!.sink.add(jsonEncode({
      'action': 'find_match',
      'variant': variant,
      'time_control_type': timeControlType,
      'time_control': timeControl,
      'rating': rating,
      'rating_range': ratingRange,
    }));
  }

  void cancelSearch() {
    print('🚫 [WS] Cancelling search');
    _channel?.sink.add(jsonEncode({'action': 'cancel_match'}));
  }

  // ✅ НОВЫЕ МЕТОДЫ ДЛЯ ИГРЫ

  void sendMove({
    required String gameId,
    required String move,
    required int whiteTime,
    required int blackTime,
  }) {
    if (_channel == null) {
      print('❌ [WS] sendMove called but channel is null');
      return;
    }

    _channel!.sink.add(jsonEncode({
      'action': 'make_move',
      'game_id': gameId,
      'move': move,
      'white_time': whiteTime,
      'black_time': blackTime,
    }));

    print('📤 [WS] Sent move: $move for game $gameId');
  }

  void resign({required String gameId}) {
    if (_channel == null) return;

    _channel!.sink.add(jsonEncode({
      'action': 'resign',
      'game_id': gameId,
    }));

    print('🏳️ [WS] Resigned game $gameId');
  }

  void disconnect() {
    print('🔌 [WS] Disconnecting...');
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    _subscription?.cancel();
    _channel?.sink.close();
    _messageController.close();
  }
}