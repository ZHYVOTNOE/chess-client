import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../cubits/matchmaking_cubit.dart';

class SearchingScreen extends StatefulWidget {
  final String variant;
  final String timeControl;
  final String ratingRange;

  const SearchingScreen({
    super.key,
    required this.variant,
    required this.timeControl,
    required this.ratingRange,
  });

  @override
  State<SearchingScreen> createState() => _SearchingScreenState();
}

class _SearchingScreenState extends State<SearchingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _radarAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _radarAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Start search when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MatchmakingCubit>().startSearch(
        variant: widget.variant,
        timeControl: widget.timeControl,
        ratingRange: widget.ratingRange,
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MatchmakingCubit, MatchmakingState>(
      listener: (context, state) {
        if (state.gameId != null) {
          // Match found - navigate to BoardScreen
          context.push('/game/play', extra: state.gameId);
        }
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${state.error}')),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Searching for opponent...'),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Radar Animation
              SizedBox(
                width: 200,
                height: 200,
                child: AnimatedBuilder(
                  animation: _radarAnimation,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _RadarPainter(_radarAnimation.value),
                      size: const Size(200, 200),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
              // Search Parameters
              _buildParameterCard(),
              const SizedBox(height: 32),
              // Cancel Button
              BlocBuilder<MatchmakingCubit, MatchmakingState>(
                builder: (context, state) {
                  return ElevatedButton(
                    onPressed: state.isSearching
                        ? () => context.read<MatchmakingCubit>().cancelSearch()
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 16,
                      ),
                    ),
                    child: const Text('Cancel Search'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParameterCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildParameterRow('Variant', widget.variant),
            const Divider(),
            _buildParameterRow('Time Control', widget.timeControl),
            const Divider(),
            _buildParameterRow('Rating Range', widget.ratingRange),
          ],
        ),
      ),
    );
  }

  Widget _buildParameterRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final double animationValue;

  _RadarPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Draw concentric circles
    final circlePaint = Paint()
      ..color = Colors.blue.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(
        center,
        radius * i / 3,
        circlePaint,
      );
    }

    // Draw radar sweep
    final sweepPaint = Paint()
      ..color = Colors.blue.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final angle = animationValue * 2 * 3.14159;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -angle,
      0.5,
      true,
      sweepPaint,
    );

    // Draw center dot
    final dotPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 5, dotPaint);
  }

  @override
  bool shouldRepaint(_RadarPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
