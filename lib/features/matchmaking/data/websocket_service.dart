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
    try {
      _channel = WebSocketChannel.connect(Uri.parse(serverUrl));

      _subscription = _channel!.stream.listen(
        (message) {
          final data = jsonDecode(message as String) as Map<String, dynamic>;
          _messageController.add(data);
        },
        onError: (error) {
          _messageController.add({'error': 'WebSocket error: $error'});
        },
        onDone: () {
          _messageController.add({'error': 'WebSocket connection closed'});
        },
      );

      // Authenticate
      _channel!.sink.add(jsonEncode({
        'action': 'authenticate',
        'token': jwtToken,
        if (userId != null) 'user_id': userId,
      }));
    } catch (e) {
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
      _messageController.add({'error': 'Not connected to server'});
      return;
    }

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
    _channel?.sink.add(jsonEncode({'action': 'cancel_match'}));
  }

  void disconnect() {
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