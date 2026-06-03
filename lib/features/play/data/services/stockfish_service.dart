import 'dart:async';
import 'package:stockfish/stockfish.dart';

class StockfishService {
  Stockfish? _stockfish;
  bool _isInitialized = false;
  StreamSubscription<String>? _stdoutSubscription;
  final _responseController = StreamController<String>.broadcast();
  String? _lastEvaluation;
  Completer<String?>? _bestMoveCompleter;

  // Bot level mapping (1-10) to Stockfish parameters
  static const Map<int, StockfishConfig> _levelConfigs = {
    1: StockfishConfig(skillLevel: 0, maxDepth: 1),
    2: StockfishConfig(skillLevel: 2, maxDepth: 3),
    3: StockfishConfig(skillLevel: 4, maxDepth: 5),
    4: StockfishConfig(skillLevel: 6, maxDepth: 8),
    5: StockfishConfig(skillLevel: 8, maxDepth: 10),
    6: StockfishConfig(skillLevel: 10, maxDepth: 12),
    7: StockfishConfig(skillLevel: 12, maxDepth: 14),
    8: StockfishConfig(skillLevel: 14, maxDepth: 16),
    9: StockfishConfig(skillLevel: 16, maxDepth: 18),
    10: StockfishConfig(skillLevel: 20, maxDepth: 20),
  };

  Future<void> initialize() async {
    if (_isInitialized) return;

    _stockfish = Stockfish();

    if (_stockfish == null) {
      throw Exception('Failed to create Stockfish instance. Only one instance can be active at a time.');
    }

    // Wait for engine to be ready
    await _waitForReady();

    // Subscribe to stdout to parse UCI responses
    _stdoutSubscription = _stockfish!.stdout.listen(_onStockfishOutput);

    _isInitialized = true;
  }

  void _onStockfishOutput(String output) {
    _responseController.add(output);

    // Parse evaluation score
    if (output.startsWith('info') && output.contains('score')) {
      _lastEvaluation = output;
    }

    // Parse best move and complete completer if waiting
    if (output.startsWith('bestmove') && _bestMoveCompleter != null) {
      final parts = output.split(' ');
      if (parts.length > 1) {
        _bestMoveCompleter!.complete(parts[1]);
      } else {
        _bestMoveCompleter!.complete(null);
      }
      _bestMoveCompleter = null;
    }
  }

  void _sendCommand(String command) {
    if (_stockfish != null) {
      _stockfish!.stdin = command; // 🔥 Используем stdin вместо send()
    }
  }

  Future<void> _waitForReady() async {
    final completer = Completer<void>();
    bool readyReceived = false;

    final subscription = _stockfish!.stdout.listen((line) { // 🔥 Используем stdout вместо output
      if (line.startsWith('readyok') || line.startsWith('uciok')) {
        if (!readyReceived) {
          readyReceived = true;
          completer.complete();
        }
      }
    });

    _sendCommand('uci');
    _sendCommand('isready');

    await completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        if (!readyReceived) {
          completer.complete();
        }
      },
    );

    await subscription.cancel();
  }

  Future<String?> evaluate(String fen, int depth) async {
    if (!_isInitialized) await initialize();

    _lastEvaluation = null;

    // Set position
    _sendCommand('position fen $fen');
    _sendCommand('go depth $depth');

    // Wait for evaluation
    await Future.delayed(Duration(milliseconds: depth * 100));

    return _lastEvaluation;
  }

  Future<String?> getBestMove(String fen, int botLevel) async {
    if (!_isInitialized) await initialize();

    final config = _levelConfigs[botLevel] ?? _levelConfigs[5]!;
    _lastEvaluation = null;

    // Set skill level
    _sendCommand('setoption name Skill Level value ${config.skillLevel}');

    // Set position
    _sendCommand('position fen $fen');

    // Get best move using Completer
    return _getBestMoveWithCompleter('go depth ${config.maxDepth}');
  }

  Future<String?> getBestMoveWithTime(String fen, int timeLimitMs) async {
    if (!_isInitialized) await initialize();

    _lastEvaluation = null;

    // Set position
    _sendCommand('position fen $fen');

    // Get best move using Completer
    return _getBestMoveWithCompleter('go movetime $timeLimitMs');
  }

  Future<String?> _getBestMoveWithCompleter(String goCommand) async {
    if (_bestMoveCompleter != null) {
      _bestMoveCompleter!.complete(null);
    }

    _bestMoveCompleter = Completer<String?>();

    _sendCommand(goCommand);

    return _bestMoveCompleter!.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        if (_bestMoveCompleter != null) {
          _bestMoveCompleter!.complete(null);
          _bestMoveCompleter = null;
        }
        return null;
      },
    );
  }

  Stream<String> get responses => _responseController.stream;

  void dispose() {
    _stdoutSubscription?.cancel();
    _bestMoveCompleter?.complete(null);
    _stockfish?.dispose(); // 🔥 dispose() автоматически отправляет 'quit'
    _responseController.close();
    _isInitialized = false;
  }
}

class StockfishConfig {
  final int skillLevel;
  final int maxDepth;

  const StockfishConfig({
    required this.skillLevel,
    required this.maxDepth,
  });
}