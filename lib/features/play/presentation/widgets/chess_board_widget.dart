import 'package:flutter/material.dart';


import 'package:squares/squares.dart';



class BoardController extends StatefulWidget {

  final BoardState state;

  final PlayState playState;

  final PieceSet pieceSet;

  final BoardTheme theme;

  final BoardSize size;

  final MarkerTheme? markerTheme;

  final void Function(Move)? onMove;

  final void Function(Move)? onAddPremove;

  final void Function()? onClearPremove;

  final PromotionBehaviour promotionBehaviour;

  final List<String> pieceHierarchy;

  final List<Move> moves;

  final bool draggable;

  final double dragFeedbackSize;

  final Offset dragFeedbackOffset;

  final DragTargetFeedback? dragTargetFeedback;

  final bool animatePieces;

  final Duration animationDuration;

  final Curve animationCurve;

  final double premovePieceOpacity;

  final LabelConfig labelConfig;

  final BackgroundConfig backgroundConfig;

  final Widget? background;

  final double piecePadding;

  final List<Widget> underlays;

  final List<Widget> overlays;



  final List<Move> premoves;



  final bool allowBothPlayers; // For local 2-player games



  String get bestPiece => pieceHierarchy.isNotEmpty ? pieceHierarchy.first : 'q';



  PlayerSet get dragPermissions => allowBothPlayers

      ? PlayerSet.both // Allow both players to move for local games

      : {

          PlayState.ourTurn: PlayerSet.fromPlayer(state.turn),

          PlayState.theirTurn: PlayerSet.fromPlayer(1 - state.turn),

          PlayState.observing: PlayerSet.both,

          PlayState.finished: PlayerSet.neither

        }[playState]!;



  BoardController({

    super.key,

    required this.state,

    required this.playState,

    required this.pieceSet,

    this.theme = BoardTheme.blueGrey,

    this.size = const BoardSize(8, 8),

    this.markerTheme,

    this.onMove,

    this.onAddPremove,

    this.onClearPremove,

    this.promotionBehaviour = PromotionBehaviour.alwaysSelect,

    this.pieceHierarchy = Squares.defaultPieceHierarchy,

    this.moves = const [],

    this.draggable = true,

    this.dragFeedbackSize = 2.0,

    this.dragFeedbackOffset = const Offset(0.0, -1.0),

    this.dragTargetFeedback,

    this.animatePieces = true,

    this.animationDuration = Squares.defaultAnimationDuration,

    this.animationCurve = Squares.defaultAnimationCurve,

    this.premovePieceOpacity = Squares.defaultPremovePieceOpacity,

    this.labelConfig = LabelConfig.standard,

    this.backgroundConfig = BackgroundConfig.standard,

    this.background,

    this.piecePadding = 0.0,

    this.overlays = const [],

    this.underlays = const [],

    this.premoves = const [],

    this.allowBothPlayers = false,

  });



  @override

  State<BoardController> createState() => _BoardControllerState();

}



class _BoardControllerState extends State<BoardController> {

  int? selection;

  int? target;

  List<Move> dests = [];

  List<PieceSelectorData> pieceSelectors = [];

  late Map<int, List<Move>> moveMap;

  late List<Move> drops;



  int get player => widget.allowBothPlayers 

      ? -1 // Allow both players for local games

      : widget.state.playerForState(widget.playState);



  @override

  void initState() {

    super.initState();

    _rebuildMoveMap();

  }



  @override

  void didUpdateWidget(covariant BoardController oldWidget) {

    if (oldWidget.moves != widget.moves || oldWidget.state != widget.state) {

      _rebuildMoveMap();

    }

    if (oldWidget.state != widget.state) {

      _onNewBoardState(oldWidget.state);

    }

    super.didUpdateWidget(oldWidget);

  }



  void _rebuildMoveMap() {

    moveMap = {};

    drops = [];

    for (Move m in widget.moves) {

      if (m.handDrop) {

        drops.add(m);

      } else {

        moveMap.putIfAbsent(m.from, () => []).add(m);

      }

    }

  }



  @override

  Widget build(BuildContext context) {

    return Board(

      state: widget.state,

      playState: widget.playState,

      pieceSet: widget.pieceSet,

      theme: widget.theme,

      size: widget.size,

      markerTheme: widget.markerTheme ??

          MarkerTheme(

            empty: MarkerTheme.dot,

            piece: MarkerTheme.corners(),

          ),

      draggable: widget.draggable,

      dragFeedbackSize: widget.dragFeedbackSize,

      dragFeedbackOffset: widget.dragFeedbackOffset,

      dragPermissions: widget.dragPermissions,

      dragTargetFeedback: widget.dragTargetFeedback,

      animatePieces: widget.animatePieces,

      animationDuration: widget.animationDuration,

      animationCurve: widget.animationCurve,

      selection: selection,

      target: target,

      pieceSelectors: pieceSelectors,

      markers: dests.map((e) => e.to).toList(),

      onTap: _onTap,

      acceptDrag: _acceptDrag,

      validateDrag: _validateDrag,

      onPieceSelected: _onPieceSelected,

      labelConfig: widget.labelConfig,

      backgroundConfig: widget.backgroundConfig,

      background: widget.background,

      piecePadding: widget.piecePadding,

      underlays: widget.underlays,

      overlays: [

        ...widget.overlays,

        // 🔥 Визуальная подсветка премувов (как на Chess.com)

        ...widget.premoves.map((pm) => _buildPremoveCellOverlay(pm)),

        // 🔥 Оверлеи фигур для промоушена/дропа

        ...widget.premoves

            .where((pm) => pm.promotion || pm.drop)

            .map((pm) => _buildPremovePieceOverlay(pm)),

      ],

    );

  }



  /// 🔥 Визуальная подсветка клетки премува (красная, как на Chess.com)

  Widget _buildPremoveCellOverlay(Move pm) {

    return Positioned.fill(

      child: CustomPaint(

        painter: _PremoveCellPainter(

          square: pm.to,

          size: widget.size,

          orientation: widget.state.orientation,

          color: Colors.red.withValues(alpha: 0.4),

        ),

      ),

    );

  }



  Widget _buildPremovePieceOverlay(Move pm) {

    if (pm.promotion) {

      return PieceOverlay.single(

        size: widget.size,

        orientation: widget.state.orientation,

        pieceSet: widget.pieceSet,

        square: pm.to,

        piece: pieceForPlayer(pm.promo!, widget.state.waitingPlayer),

        opacity: widget.premovePieceOpacity,

      );

    }

    if (pm.drop) {

      return PieceOverlay.single(

        size: widget.size,

        orientation: widget.state.orientation,

        pieceSet: widget.pieceSet,

        square: pm.dropSquare!,

        piece: pieceForPlayer(pm.piece!, widget.state.waitingPlayer),

        opacity: widget.premovePieceOpacity,

      );

    }

    return const SizedBox.shrink();

  }



  void _onNewBoardState(BoardState lastState) {

    if (widget.state.orientation != lastState.orientation) {

      _closePieceSelectors();

    }

    if (selection != null) {

      _setSelection(selection!);

    }

    if (target != null) {

      setState(() {

        target = null;

        selection = null;

        dests = [];

      });

    }

  }



  void _onTap(int square) {

    // For local games, always allow moves regardless of playState

    if (widget.allowBothPlayers) {

      if (selection == null) {

        return _setSelection(square);

      }

      if (selection == square) {

        return _clearSelection();

      }

      final moves = dests.to(square);

      if (moves.isEmpty) {

        return _setSelection(square);

      }

      final promoMoves = moves.promoMoves;

      final gatingMoves = moves.gatingMoves;

      if (gatingMoves.isNotEmpty) {

        final gatingSquares = <int?>{};

        for (final m in gatingMoves) gatingSquares.add(m.gatingSquare);

        for (final x in gatingSquares) {

          _openPieceSelector(square, gate: true, gatingSquare: x, disambiguateGating: gatingSquares.length > 1);

        }

      } else if (promoMoves.isNotEmpty) {

        final showSelector = widget.promotionBehaviour == PromotionBehaviour.alwaysSelect ||

            widget.promotionBehaviour == PromotionBehaviour.autoPremove;

        if (!showSelector) {

          final m = promoMoves.bestPromo(widget.pieceHierarchy);

          if (m != null) return _onMove.call(m);

        }

        _openPieceSelector(square);

      } else {

        _onMove.call(moves.first);

      }

      return;

    }

    // Normal behavior for bot/online games

    if (widget.playState == PlayState.ourTurn) {

      return _handleMoveTap(square, _onMove);

    }

    if (widget.playState == PlayState.theirTurn) {

      return _handleMoveTap(square, _setPremove, true);

    }

    setState(() => selection = square);

  }



  void _onPieceSelected(PieceSelectorData data, int index) {

    if (pieceSelectors.isEmpty || selection == null || widget.onMove == null) {

      return _closePieceSelectors();

    }

    String? piece = data.pieces[index];

    if (piece != null) piece = piece.toLowerCase();



    Move move = !data.gate

        ? Move(from: selection!, to: data.square, promo: piece)

        : Move(

      from: selection!,

      to: data.square,

      piece: piece,

      gatingSquare: data.disambiguateGating ? data.gatingSquare : null,

    );



    // For local games, allow both players to move regardless of playState

    if (widget.allowBothPlayers) {

      _onMove(move);

    } else if (widget.playState != PlayState.theirTurn) {

      _onMove(move);

    } else {

      _setPremove(move);

    }

  }



  bool _validateDrag(PartialMove partial, int to) {

    if (partial.drop) {

      if (drops.isEmpty) return false;

      return drops.to(to).withPiece(partial.piece).isNotEmpty;

    }

    if (moveMap[partial.from] == null) return false;

    return moveMap[partial.from]!.any((m) => m.to == to);

  }



  void _acceptDrag(PartialMove partial, int to) {

    if (partial.drop) {

      _onDrop(partial, to);

    } else {

      _setSelection(partial.from);

      _onTap(to);

    }

  }



  void _handleMoveTap(int square, void Function(Move)? onMove,

      [bool isPremove = false]) {

    if (selection == null) {

      return _setSelection(square);

    }



    // 🔥 Клик по той же клетке -> отмена всей цепи премувов

    if (selection == square) {

      if (isPremove) {

        debugPrint('🚫 [UI] Cancelling entire premove chain (same square)');

        widget.onClearPremove?.call();

      }

      return _clearSelection();

    }



    // 🔥 Проверяем валидность хода

    final moves = dests.to(square);

    if (moves.isEmpty) {

      // 🔥 Клик по пустой/невалидной клетке -> отмена всей цепи премувов

      if (isPremove) {

        debugPrint('🚫 [UI] Cancelling entire premove chain (invalid square)');

        widget.onClearPremove?.call();

        _clearSelection();

        return;

      }

      return _setSelection(square);

    }



    final promoMoves = moves.promoMoves;

    final gatingMoves = moves.gatingMoves;



    if (gatingMoves.isNotEmpty) {

      final gatingSquares = <int?>{};

      for (final m in gatingMoves) gatingSquares.add(m.gatingSquare);

      for (final x in gatingSquares) {

        _openPieceSelector(square, gate: true, gatingSquare: x, disambiguateGating: gatingSquares.length > 1);

      }

    } else if (promoMoves.isNotEmpty) {

      final showSelector = widget.promotionBehaviour == PromotionBehaviour.alwaysSelect ||

          (!isPremove && widget.promotionBehaviour == PromotionBehaviour.autoPremove);

      if (!showSelector) {

        final m = promoMoves.bestPromo(widget.pieceHierarchy);

        if (m != null) return onMove?.call(m);

      }

      _openPieceSelector(square);

    } else {

      onMove?.call(moves.first);

    }

  }



  void _setSelection(int square) {

    setState(() {

      selection = square;

      target = null;

      // For local games, show all moves from moveMap

      dests = moveMap[square] ?? [];

      pieceSelectors = [];

    });

  }



  void _clearSelection() {

    setState(() {

      selection = null;

      target = null;

      dests = [];

      pieceSelectors = [];

    });

  }



  void _setTarget(int square) {

    setState(() {

      target = square;

      dests = [];

    });

  }



  void _onMove(Move move) {

    widget.onMove?.call(move);

    _clearSelection();

  }



  void _setPremove(Move move) {

    widget.onAddPremove?.call(move);

    _setTarget(move.to);

    _closePieceSelectors();

  }



  void _openPieceSelector(int square, {bool gate = false, int? gatingSquare, bool disambiguateGating = false}) {

    final moves = widget.moves.from(selection!).to(square).where((e) => gate ? (e.gatingSquare == gatingSquare || e.gatingSquare == null) : true).toList();

    final pieces = moves.map<String?>((e) => gate ? e.piece : e.promo).toList();

    pieces.sort(_promoComp);

    if (player == Squares.white) {

      pieces.replaceRange(0, pieces.length, pieces.map((e) => e?.toUpperCase()).toList());

    }



    setState(() {

      pieceSelectors.add(PieceSelectorData(

        square: square, startLight: widget.size.isLightSquare(square), pieces: pieces,

        gate: gate, gatingSquare: gatingSquare, disambiguateGating: disambiguateGating,

      ));

    });

  }



  void _closePieceSelectors() => setState(() => pieceSelectors = []);



  int _promoComp(String? a, String? b) {

    if (a == null) return -1;

    if (b == null) return 1;

    return widget.pieceHierarchy.indexOf(a).compareTo(widget.pieceHierarchy.indexOf(b));

  }



  void _onDrop(PartialMove partial, int to) {

    final targetMoves = drops.to(to).withPiece(partial.piece);

    if (targetMoves.isEmpty) _clearSelection();

    else {

      if (widget.playState == PlayState.ourTurn) _onMove(targetMoves.first);

      else if (widget.playState == PlayState.theirTurn) _setPremove(targetMoves.first);

    }

  }

}



// 🔥 CustomPainter для визуальной подсветки премувов (как на Chess.com)

// С учётом orientation (переворота доски за чёрных)

class _PremoveCellPainter extends CustomPainter {

  final int square;

  final BoardSize size;

  final int orientation;

  final Color color;



  _PremoveCellPainter({

    required this.square, required this.size, required this.orientation,

    required this.color,

  });



  @override

  void paint(Canvas canvas, Size canvasSize) {

    final squareSize = canvasSize.width / size.h;

    final file = square % size.h.toInt();

    final rank = square ~/ size.h.toInt();



    // 🔥 x инвертируется при orientation == 1 (чёрные)

    final x = (orientation == 0 ? file : size.h.toInt() - 1 - file) * squareSize;



    // 🔥 y всегда инвертируется (1-я горизонталь внизу, 8-я вверху)

    final y = (size.v.toInt() - 1 - rank) * squareSize;



    final paint = Paint()

      ..color = color

      ..style = PaintingStyle.fill;



    canvas.drawRect(

      Rect.fromLTWH(x, y, squareSize, squareSize),

      paint,

    );

  }



  @override

  bool shouldRepaint(covariant _PremoveCellPainter oldDelegate) {

    return oldDelegate.square != square ||

        oldDelegate.color != color ||

        oldDelegate.orientation != orientation;

  }

}