import 'dart:math';
import 'package:bishop/bishop.dart' as bishop;

import 'player_color.dart';
import 'engine_config.dart';
import 'time_control.dart';

enum OpponentType {
  randomMover('Random Mover'),
  ai('AI'),
  human('Human');

  final String title;
  const OpponentType(this.title);

  bool get isBot => this == ai || this == randomMover;
}

class GameConfig {
  final String id;
  final bishop.Variant variant;
  final PlayerColor humanPlayer;
  final OpponentType opponentType;
  final EngineConfig engineConfig;
  final TimeControl timeControl;
  final String? fen;
  final String? friendId;
  final bool rated;

  GameConfig._({
    required this.id,
    required this.variant,
    required this.humanPlayer,
    required this.opponentType,
    required this.engineConfig,
    required this.timeControl,
    this.fen,
    this.friendId,
    this.rated = true,
  });

  factory GameConfig.create({
    required bishop.Variant variant,
    PlayerColor? humanPlayer,
    OpponentType? opponentType,
    EngineConfig? engineConfig,
    TimeControl? timeControl,
    String? fen,
    String? friendId,
    bool? rated,
  }) {
    final resolvedOpponent = opponentType ?? OpponentType.ai;

    return GameConfig._(
      id: '${DateTime.now().millisecondsSinceEpoch}_${_randomId()}',
      variant: variant,
      humanPlayer: humanPlayer ?? PlayerColor.random(),
      opponentType: resolvedOpponent,
      engineConfig: engineConfig ?? (
          resolvedOpponent == OpponentType.ai
              ? const EngineConfig()
              : const EngineConfig(timeLimitMs: 0)
      ),
      timeControl: timeControl ?? const TimeControl.disabled(),
      fen: (fen?.isEmpty ?? true) ? null : fen,
      friendId: friendId,
      rated: rated ?? true,
    );
  }

  static String _randomId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(4, (_) => chars[Random().nextInt(chars.length)]).join();
  }

  bool get isValidFen => fen == null
      ? true
      : bishop.validateFen(variant: variant, fen: fen!);

  bool get isVsBot => opponentType.isBot;
  bool get hasTimeControl => timeControl.enabled;

  //GameConfig copyWith({...}) => ...;
}