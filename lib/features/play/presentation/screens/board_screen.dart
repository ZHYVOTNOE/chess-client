// import 'dart:io';

//

// import 'package:client/features/play/domain/entities/game_config.dart';

// import 'package:client/features/play/domain/utils/board_orientation.dart';

// import 'package:flutter/material.dart';

// import 'package:go_router/go_router.dart';

// import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

// import 'package:provider/provider.dart';

// import 'package:squares/squares.dart' hide BoardController;

//

// import '../../../core/providers/settings_provider.dart';

// import '../../../core/providers/user_provider.dart';

// import '../../../core/utils/piece_set_loader.dart';

// import '../../settings/constants/custom_board_themes.dart';

// import '../domain/game_engine.dart';

// import 'widgets/board_controller.dart';

//

// class BoardScreen extends StatelessWidget {

//   final GameConfig config;

//   final String? gameId; // For online games

//   final String? whiteId; // For online games

//   final String? blackId; // For online games

//

//   const BoardScreen({

//     super.key,

//     required this.config,

//     this.gameId,

//     this.whiteId,

//     this.blackId,

//   });

//

//   @override

//   Widget build(BuildContext context) {

//     return ChangeNotifierProvider(

//       create: (_) => GameEngine(config),

//       child: _BoardView(

//         gameId: gameId,

//         whiteId: whiteId,

//         blackId: blackId,

//       ),

//     );

//   }

// }

//

// class _BoardView extends StatelessWidget {

//   final String? gameId;

//   final String? whiteId;

//   final String? blackId;

//

//   const _BoardView({

//     this.gameId,

//     this.whiteId,

//     this.blackId,

//   });

//

//   @override

//   Widget build(BuildContext context) {

//     final engine = context.watch<GameEngine>();

//     final snapshot = engine.snapshot;

//     final state = snapshot.squaresState;

//

//     // Determine board orientation based on player color

//     // For online games, use whiteId/blackId; for local/bot, use config.humanPlayer

//     final shouldFlip = engine.config.isOnline

//         ? BoardOrientation.shouldFlipBoard(

//             whiteId: whiteId,

//             blackId: blackId,

//           )

//         : engine.config.humanPlayer.value == 1; // 1 = black, so flip if playing as black

//

//     final boardAspectRatio = state.size.aspectRatio;

//     final hasTimeControl = engine.config.timeControl.isEnabled;

//     final isWhite = !shouldFlip;

//     final topTime = isWhite ? snapshot.blackTime : snapshot.whiteTime;

//     final bottomTime = isWhite ? snapshot.whiteTime : snapshot.blackTime;

//

//     final nickname = context.select<UserProvider, String>((u) => u.nickname);

//     final avatar = context.select<UserProvider, File?>((u) => u.avatarFile);

//

//     final settings = context.watch<SettingsProvider>();

//     final boardTheme = CustomBoardThemes.all

//         .firstWhere((entry) => entry.id == settings.settings?.boardTheme,

//         orElse: () => CustomBoardThemes.all[0])

//         .theme;

//

//     return Scaffold(

//       appBar: AppBar(

//         title: Text(engine.config.variant.name),

//         leading: IconButton(

//           icon: const Icon(Icons.arrow_back),

//           onPressed: () => context.pop(),

//         ),

//       ),

//       body: Column(

//         mainAxisAlignment: MainAxisAlignment.center,

//         children: [

//           _PlayerCard(

//             name: engine.config.isVsBot ? 'Stockfish' : 'Opponent',

//             rating: engine.config.isVsBot ? 2800 : null,

//             time: topTime,

//             isThinking: snapshot.isBotThinking,

//             showTime: hasTimeControl,

//           ),

//

//           Flexible(

//             fit: FlexFit.loose,

//             child: Center(

//               child: AspectRatio(

//                 aspectRatio: boardAspectRatio,

//                 // 🔥 Пересборка при изменении премува

//                 child: ValueListenableBuilder<Move?>(

//                   valueListenable: ValueNotifier(engine.premove),

//                   builder: (context, premove, child) {

//                     return Stack(

//                       children: [

//                         Transform.rotate(

//                           angle: shouldFlip ? 3.14159 : 0,

//                           child: BoardController(

//                             key: ValueKey('board-${snapshot.fen}-${premove?.toString()}'),

//                             state: state.board,

//                             playState: snapshot.isGameOver ? PlayState.finished : state.state,

//                             size: state.size,

//                             pieceSet: PieceSetLoader.load(settings.settings?.pieceSet ?? 'merida'),

//                             theme: boardTheme,

//                             moves: state.moves,

//                             onMove: engine.makeMove,

//                             onAddPremove: engine.addPremove,

//                             onClearPremove: engine.clearPremove,

//                             premoves: premove != null ? [premove] : [],

//                             markerTheme: MarkerTheme(

//                               empty: MarkerTheme.dot,

//                               piece: MarkerTheme.corners(),

//                             ),

//                             promotionBehaviour: PromotionBehaviour.autoPremove,

//                           ),

//                         ),

//                         // 🔥 Визуальный индикатор премува (Личесс-стиль)

//                         if (premove != null)

//                           Positioned.fill(

//                             child: IgnorePointer(

//                               child: CustomPaint(

//                                 painter: _PremoveHighlightPainter(

//                                   premove: premove,

//                                   boardSize: state.size,

//                                   isFlipped: shouldFlip,

//                                 ),

//                               ),

//                             ),

//                           ),

//                       ],

//                     );

//                   },

//                 ),

//               ),

//             ),

//           ),

//

//           _PlayerCard(

//             name: nickname,

//             rating: 2600,

//             time: bottomTime,

//             isThinking: false,

//             avatar: avatar,

//             showTime: hasTimeControl,

//           ),

//

//           if (snapshot.result != null)

//             Padding(

//               padding: const EdgeInsets.all(16),

//               child: Text(

//                 snapshot.result!,

//                 style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),

//               ),

//             ),

//

//           _GameControls(

//             onFlip: engine.flipBoard,

//             onResign: engine.resign,

//             onDrawOffer: engine.offerDraw,

//           ),

//         ],

//       ),

//     );

//   }

// }

//

// class _PlayerCard extends StatelessWidget {

//   final String name;

//   final int? rating;

//   final Duration time;

//   final bool isThinking;

//   final File? avatar;

//   final bool showTime;

//

//   const _PlayerCard({

//     required this.name, this.rating, required this.time,

//     required this.isThinking, this.avatar, this.showTime = true,

//   });

//

//   @override

//   Widget build(BuildContext context) {

//     final m = time.inMinutes.remainder(60);

//     final s = time.inSeconds.remainder(60);

//

//     return ListTile(

//       leading: CircleAvatar(

//         backgroundColor: Colors.grey.shade300,

//         backgroundImage: avatar != null ? FileImage(avatar!) : null,

//         child: avatar == null ? Icon(Icons.person, color: Colors.grey.shade600) : null,

//       ),

//       title: Text(name),

//       subtitle: rating != null ? Text('Rating: $rating') : null,

//       trailing: isThinking

//           ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))

//           : showTime

//           ? Text('$m:${s.toString().padLeft(2, '0')}', style: const TextStyle(fontFamily: 'monospace'))

//           : null,

//     );

//   }

// }

//

// class _GameControls extends StatelessWidget {

//   final VoidCallback onFlip;

//   final VoidCallback onResign;

//   final VoidCallback onDrawOffer;

//

//   const _GameControls({required this.onFlip, required this.onResign, required this.onDrawOffer});

//

//   @override

//   Widget build(BuildContext context) {

//     return Row(

//       mainAxisAlignment: MainAxisAlignment.spaceEvenly,

//       children: [

//         IconButton(onPressed: onDrawOffer, icon: const Text('½', style: TextStyle(fontSize: 22))),

//         IconButton(onPressed: onFlip, icon: Icon(MdiIcons.rotate3DVariant)),

//         IconButton(onPressed: onResign, icon: Icon(MdiIcons.flag)),

//       ],

//     );

//   }

// }

//

// class _PremoveHighlightPainter extends CustomPainter {

//   final Move premove;

//   final BoardSize boardSize;

//   final bool isFlipped;

//

//   _PremoveHighlightPainter({

//     required this.premove,

//     required this.boardSize,

//     required this.isFlipped,

//   });

//

//   @override

//   void paint(Canvas canvas, Size size) {

//     final paint = Paint()

//       ..color = Colors.blue.withOpacity(0.3)

//       ..style = PaintingStyle.fill;

//

//     final squareSize = size.width / boardSize.h;

//

//     // Get square coordinates

//     final fromX = (premove.from % boardSize.h) * squareSize;

//     final fromY = (premove.from ~/ boardSize.h) * squareSize;

//     final toX = (premove.to % boardSize.h) * squareSize;

//     final toY = (premove.to ~/ boardSize.h) * squareSize;

//

//     // Draw highlight on from square

//     canvas.drawRect(

//       Rect.fromLTWH(fromX, fromY, squareSize, squareSize),

//       paint,

//     );

//

//     // Draw highlight on to square

//     canvas.drawRect(

//       Rect.fromLTWH(toX, toY, squareSize, squareSize),

//       paint,

//     );

//

//     // Draw arrow

//     final arrowPaint = Paint()

//       ..color = Colors.blue.withOpacity(0.6)

//       ..style = PaintingStyle.stroke

//       ..strokeWidth = 3;

//

//     canvas.drawLine(

//       Offset(fromX + squareSize / 2, fromY + squareSize / 2),

//       Offset(toX + squareSize / 2, toY + squareSize / 2),

//       arrowPaint,

//     );

//   }

//

//   @override

//   bool shouldRepaint(_PremoveHighlightPainter oldDelegate) {

//     return oldDelegate.premove != premove ||

//         oldDelegate.boardSize != boardSize ||

//         oldDelegate.isFlipped != isFlipped;

//   }

// }



import 'dart:io';



import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:go_router/go_router.dart';

import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import 'package:provider/provider.dart';

import 'package:bishop/bishop.dart' as bishop;
import 'package:squares/squares.dart' hide BoardController;



import '../../../../core/providers/locale_provider.dart';

import '../../../../core/providers/settings_provider.dart';

import '../../../../core/providers/user_provider.dart';

import '../../../../core/utils/piece_set_loader.dart';

import '../../../settings/constants/custom_board_themes.dart';

import '../../domain/entities/game_config.dart';

import '../../domain/game_engine.dart';

import '../widgets/board_controller.dart';



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
    final avatarUrl = context.select<UserProvider, String?>((u) => u.avatarUrl);
    final gameMode = engine.config.timeControl.gameMode;
    final playerRating = context.select<UserProvider, int?>((u) => u.getRating(gameMode));

    final settings = context.watch<SettingsProvider>();

    if (settings.settings == null && !settings.isLoading) {
      final userId = context.read<UserProvider>().userId;
      if (userId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<SettingsProvider>().loadSettings(userId);
        });
      }
      return _loadingScaffold(engine);
    }

    if (settings.isLoading) return _loadingScaffold(engine);

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
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Высота под карточки игроков и отступы
                const playerCardHeight = 72.0;
                const resultHeight = 40.0;
                final availableForBoard = constraints.maxHeight
                    - playerCardHeight * 2
                    - resultHeight;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _PlayerCard(
                      name: engine.config.opponentName ??
                          (engine.config.isVsBot ? 'Stockfish' : 'Opponent'),
                      rating: engine.config.opponentRating,
                      avatarUrl: engine.config.opponentAvatarUrl,
                      time: topTime,
                      isThinking: snapshot.isBotThinking,
                      showTime: hasTimeControl,
                    ),

                    // Доска ограничена доступным местом
                    SizedBox(
                      height: availableForBoard.clamp(100.0, constraints.maxWidth / boardAspectRatio),
                      child: AspectRatio(
                        aspectRatio: boardAspectRatio,
                        child: ValueListenableBuilder<List<Move>>(
                          valueListenable: ValueNotifier(engine.premoveQueue),
                          builder: (context, premoves, child) {
                            return BoardController(
                              key: ValueKey('board-${premoves.length}'),
                              state: state.board,
                              playState: snapshot.isGameOver
                                  ? PlayState.finished
                                  : state.state,
                              size: state.size,
                              pieceSet: _requiresExtendedPieces(engine.config.variant)
                                  ? PieceSet.merida()
                                  : PieceSetLoader.load(settings.settings?.pieceSet ?? 'merida'),
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

                    _PlayerCard(
                      name: nickname,
                      rating: playerRating,
                      time: bottomTime,
                      isThinking: false,
                      avatar: avatar,
                      avatarUrl: avatarUrl,
                      showTime: hasTimeControl,
                    ),

                    if (snapshot.result != null)
                      Padding(
                        padding: EdgeInsets.only(top: 4.r),
                        child: Text(
                          snapshot.result!,
                          style: TextStyle(
                              fontSize: 20.sp, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          // ✅ Кнопки посередине между профилем и низом экрана
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: _GameControls(
              onFlip: engine.flipBoard,
              onResign: engine.resign,
              onDrawOffer: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingScaffold(GameEngine engine) {
    return Scaffold(
      appBar: AppBar(title: Text(engine.config.variant.name)),
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  bool _requiresExtendedPieces(bishop.Variant variant) {
    const standardPieces = {'P', 'N', 'B', 'R', 'Q', 'K'};

    const meridaExtended = {'A', 'C', 'H', 'E', 'S', 'X'};

    return variant.pieceTypes.keys.any(
          (symbol) => meridaExtended.contains(symbol),
    );
  }
}



class _PlayerCard extends StatelessWidget {

  final String name;

  final int? rating;

  final Duration time;

  final bool isThinking;

  final File? avatar;
  final String? avatarUrl;

  final bool showTime;



  const _PlayerCard({

    required this.name, this.rating, required this.time,

    required this.isThinking, this.avatar, this.avatarUrl, this.showTime = true,

  });



  @override

  Widget build(BuildContext context) {

    final locale = context.watch<LocaleProvider>();

    final m = time.inMinutes.remainder(60);

    final s = time.inSeconds.remainder(60);



    return ListTile(

      leading: CircleAvatar(

        backgroundColor: Colors.grey.shade300,

        backgroundImage: avatar != null ? FileImage(avatar!) : (avatarUrl != null ? NetworkImage(avatarUrl!) : null),

        child: avatar == null && avatarUrl == null ? Icon(Icons.person, color: Colors.grey.shade600) : null,

      ),

      title: Text(name),

      subtitle: rating != null ? Text('${locale.get('board_rating')} $rating') : null,

      trailing: isThinking

          ? SizedBox(width: 20.r, height: 20.r, child: CircularProgressIndicator(strokeWidth: 2))

          : showTime

          ? Text('$m:${s.toString().padLeft(2, '0')}', style: TextStyle(fontFamily: 'monospace', fontSize: 14.sp))

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