import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bishop/bishop.dart' as bishop;
import '../../../../core/providers/locale_provider.dart';
import '../../../play/data/datasources/ratings_remote_datasource.dart';
import '../../../play/data/repositories/rating_repository_impl.dart';
import '../../../play/domain/entities/engine_config.dart';
import '../../../play/domain/entities/game_config.dart';
import '../../../play/domain/entities/player_color.dart';
import '../../../play/domain/entities/time_control.dart';
import '../../../play/domain/repositories/rating_repository.dart';
import '../cubits/matchmaking_cubit.dart';

class SearchingScreen extends StatefulWidget {
  final String variant;
  final String timeControl;
  final String timeControlType;
  final int rating;
  final String ratingRange;

  const SearchingScreen({
    super.key,
    required this.variant,
    required this.timeControl,
    required this.timeControlType,
    required this.rating,
    required this.ratingRange,
  });

  @override
  State<SearchingScreen> createState() => _SearchingScreenState();
}

class _SearchingScreenState extends State<SearchingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  String? _jwtToken;
  late final RatingRepository _ratingRepository;
  bool _hasNavigated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = GoRouterState.of(context);
    final params = state.extra as Map<String, dynamic>?;
    _jwtToken = params?['jwtToken'] as String?;
    final userId = params?['userId'] as String?;
    print('🔑 [DEBUG] JWT Token: $_jwtToken');
    if (_jwtToken != null) {
      // ✅ Только connect — findMatch вызывается из initState после
      context.read<MatchmakingCubit>().connect(_jwtToken!, userId: userId);
    }
  }

  @override
  void initState() {
    super.initState();
    _ratingRepository = RatingRepositoryImpl(
      RatingsRemoteDataSource(Supabase.instance.client),
    );
    
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Start search when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🔍 [SearchingScreen] findMatch params:');
      print('   variant: ${widget.variant}');
      print('   timeControlType: ${widget.timeControlType}');
      print('   timeControl: ${widget.timeControl}');
      print('   rating: ${widget.rating}');
      print('   ratingRange: ${widget.ratingRange}');
      context.read<MatchmakingCubit>().findMatch(
        variant: widget.variant,
        timeControlType: widget.timeControlType,
        timeControl: widget.timeControl,
        rating: widget.rating,
        ratingRange: _parseRatingRange(widget.ratingRange),
      );
    });
  }

  int _parseRatingRange(String range) {
    int result;
    if (range == 'any') {
      result = 9999;
    } else if (range.startsWith('±')) {
      result = int.tryParse(range.substring(1)) ?? 200;
    } else {
      result = int.tryParse(range) ?? 200;
    }
    print('🎯 [parseRatingRange] "$range" → $result');
    return result;
  }

  bishop.Variant _getVariant(String variant) {
    switch (variant) {
      case 'standard':
      case 'Chess':
        return bishop.Variant.standard();
      case 'chess960':
        return bishop.Variant.chess960();
      case 'crazyhouse':
        return bishop.Variant.crazyhouse();
      case 'atomic':
        return bishop.Variant.atomic();
      case 'horde':
        return bishop.Variant.horde();
      case 'kingOfTheHill':
        return bishop.Variant.kingOfTheHill();
      default:
        return bishop.Variant.standard();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocConsumer<MatchmakingCubit, MatchmakingState>(
        listener: (context, state) async {
          if (state.gameId != null) {
            // Load opponent profile data
            final opponentId = state.yourColor == 'white' ? state.blackId : state.whiteId;
            if (opponentId == null) {
              print('❌ [SearchingScreen] Opponent ID is null');
              return;
            }
            
            String? opponentName;
            String? opponentAvatarUrl;
            int? opponentRating;

            try {
              // Load opponent profile
              final profileResponse = await Supabase.instance.client
                  .from('profiles')
                  .select('nickname, avatar_url')
                  .eq('id', opponentId)
                  .maybeSingle();

              if (profileResponse != null) {
                opponentName = profileResponse['nickname'] as String?;
                opponentAvatarUrl = profileResponse['avatar_url'] as String?;
              }

              // Load opponent rating
              // Map variant name to database format
              final variantName = widget.variant == 'Chess' ? 'standard' : widget.variant;
              final rating = await _ratingRepository.getRating(
                opponentId,
                variantName,
                widget.timeControlType,
              );
              opponentRating = rating?.rating.toInt();
            } catch (e) {
              // Silently handle errors
            }

            // Create GameConfig with opponent data
            final config = GameConfig.create(
              variant: _getVariant(widget.variant),
              humanPlayer: state.yourColor == 'white' ? PlayerColor.white : PlayerColor.black,
              opponentType: OpponentType.human,
              timeControl: TimeControl.parse(widget.timeControl),
              opponentName: opponentName ?? 'Opponent',
              opponentRating: opponentRating,
              opponentAvatarUrl: opponentAvatarUrl,
              // ✅ ПЕРЕДАЕМ ДАННЫЕ ОНЛАЙН-ИГРЫ
              gameId: state.gameId,
              whiteId: state.whiteId,
              blackId: state.blackId,
              initialFen: state.initialFen,
            );

            // Navigate to game screen
            context.go('/game/play', extra: config);
          } else if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error!)),
            );
          }
        },
        builder: (context, state) {
          final locale = context.read<LocaleProvider>();
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Radar Animation
                SizedBox(
                  width: 200.r,
                  height: 200.r,
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: RadarPainter(_animation.value),
                        size: Size(200.r, 200.r),
                      );
                    },
                  ),
                ),
                SizedBox(height: 40.h),
                Text(
                  locale.get('searching_opponent'),
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20.h),
                if (state.isSearching)
                  Column(
                    children: [
                      SizedBox(height: 20.h),
                      ElevatedButton(
                        onPressed: () {
                          final cubit = context.read<MatchmakingCubit>();
                          cubit.cancelSearch();
                          context.pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(locale.get('searching_cancel')),
                      ),
                    ],
                  )
                else
                  ElevatedButton(
                    onPressed: () {
                      context.pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(locale.get('searching_back')),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class RadarPainter extends CustomPainter {
  final double animationValue;

  RadarPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10.r;

    // Draw radar circles
    for (int i = 3; i >= 1; i--) {
      final circleRadius = radius * (i / 3);
      final opacity = (1 - (i - 1) / 3) * animationValue;

      final paint = Paint()
        ..color = Colors.blue.withOpacity(opacity * 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.r;

      canvas.drawCircle(center, circleRadius, paint);
    }

    // Draw scanning line
    final angle = animationValue * 2 * 3.14159;
    final lineEnd = Offset(
      center.dx + radius * cos(angle),
      center.dy + radius * sin(angle),
    );

    final linePaint = Paint()
      ..color = Colors.blue.withOpacity(animationValue)
      ..strokeWidth = 3.r;

    canvas.drawLine(center, lineEnd, linePaint);

    // Draw center dot
    final dotPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 5.r, dotPaint);
  }

  @override
  bool shouldRepaint(RadarPainter oldDelegate) => true;
}