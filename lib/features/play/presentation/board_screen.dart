import 'dart:io';

import 'package:client/features/play/domain/entities/game_config.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:squares/squares.dart' hide BoardController;

import '../../../core/providers/settings_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/utils/piece_set_loader.dart';
import '../../settings/constants/custom_board_themes.dart';
import '../domain/game_engine.dart';
import 'widgets/board_controller.dart';

class BoardScreen extends StatelessWidget {
  final GameConfig config;
  const BoardScreen({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameEngine(config),
      child: const _BoardView(),
    );
  }
}

class _BoardView extends StatelessWidget {
  const _BoardView();

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<GameEngine>();
    final snapshot = engine.snapshot;
    final state = snapshot.squaresState;

    final boardAspectRatio = state.size.aspectRatio;
    final hasTimeControl = engine.config.timeControl.isEnabled;
    final isWhite = engine.config.humanPlayer.isWhite;
    final topTime = isWhite ? snapshot.blackTime : snapshot.whiteTime;
    final bottomTime = isWhite ? snapshot.whiteTime : snapshot.blackTime;

    final nickname = context.select<UserProvider, String>((u) => u.nickname);
    final avatar = context.select<UserProvider, File?>((u) => u.avatarFile);

    final settings = context.watch<SettingsProvider>();
    final boardTheme = CustomBoardThemes.all
        .firstWhere((entry) => entry.id == settings.settings?.boardTheme,
        orElse: () => CustomBoardThemes.all[0])
        .theme;

    return Scaffold(
      appBar: AppBar(
        title: Text(engine.config.variant.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PlayerCard(
            name: engine.config.isVsBot ? 'Stockfish' : 'Opponent',
            rating: engine.config.isVsBot ? 2800 : null,
            time: topTime,
            isThinking: snapshot.isBotThinking,
            showTime: hasTimeControl,
          ),

          Flexible(
            fit: FlexFit.loose,
            child: Center(
              child: AspectRatio(
                aspectRatio: boardAspectRatio,
                // 🔥 Пересборка при изменении очереди премувов
                child: ValueListenableBuilder<List<Move>>(
                  valueListenable: ValueNotifier(engine.premoveQueue),
                  builder: (context, premoves, child) {
                    return BoardController(
                      key: ValueKey('board-${premoves.length}-${DateTime.now().millisecondsSinceEpoch ~/ 1000}'),
                      state: state.board,
                      playState: snapshot.isGameOver ? PlayState.finished : state.state,
                      size: state.size,
                      pieceSet: PieceSetLoader.load(settings.settings?.pieceSet ?? 'merida'),
                      theme: boardTheme,
                      moves: state.moves,
                      onMove: engine.makeMove,
                      onAddPremove: engine.addPremove,
                      onClearPremove: engine.clearPremove,
                      premoves: premoves,
                      markerTheme: MarkerTheme(
                        empty: MarkerTheme.dot,
                        piece: MarkerTheme.corners(),
                      ),
                      promotionBehaviour: PromotionBehaviour.autoPremove,
                    );
                  },
                ),
              ),
            ),
          ),

          _PlayerCard(
            name: nickname,
            rating: 2600,
            time: bottomTime,
            isThinking: false,
            avatar: avatar,
            showTime: hasTimeControl,
          ),

          if (snapshot.result != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                snapshot.result!,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),

          _GameControls(
            onFlip: engine.flipBoard,
            onResign: engine.resign,
            onDrawOffer: () {},
          ),
        ],
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  final String name;
  final int? rating;
  final Duration time;
  final bool isThinking;
  final File? avatar;
  final bool showTime;

  const _PlayerCard({
    required this.name, this.rating, required this.time,
    required this.isThinking, this.avatar, this.showTime = true,
  });

  @override
  Widget build(BuildContext context) {
    final m = time.inMinutes.remainder(60);
    final s = time.inSeconds.remainder(60);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.grey.shade300,
        backgroundImage: avatar != null ? FileImage(avatar!) : null,
        child: avatar == null ? Icon(Icons.person, color: Colors.grey.shade600) : null,
      ),
      title: Text(name),
      subtitle: rating != null ? Text('Rating: $rating') : null,
      trailing: isThinking
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : showTime
          ? Text('$m:${s.toString().padLeft(2, '0')}', style: const TextStyle(fontFamily: 'monospace'))
          : null,
    );
  }
}

class _GameControls extends StatelessWidget {
  final VoidCallback onFlip;
  final VoidCallback onResign;
  final VoidCallback onDrawOffer;

  const _GameControls({required this.onFlip, required this.onResign, required this.onDrawOffer});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(onPressed: onDrawOffer, icon: const Text('½', style: TextStyle(fontSize: 22))),
        IconButton(onPressed: onFlip, icon: Icon(MdiIcons.rotate3DVariant)),
        IconButton(onPressed: onResign, icon: Icon(MdiIcons.flag)),
      ],
    );
  }
}