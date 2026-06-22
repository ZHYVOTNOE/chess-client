import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/providers/locale_provider.dart';

class PuzzleStats extends StatelessWidget {
  final int streak;
  final int solvedToday;
  final int userRating;
  final int elapsedSeconds;
  final int? ratingDelta;

  const PuzzleStats({
    super.key,
    this.streak = 0,
    this.solvedToday = 0,
    this.userRating = 1500,
    this.elapsedSeconds = 0,
    this.ratingDelta,
  });

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: _StatItem(
                icon: Icons.local_fire_department,
                value: '$streak',
                label: locale.get('puzzle_streak'),
                color: Colors.orange,
              ),
            ),
            Expanded(
              child: _StatItem(
                icon: Icons.check_circle,
                value: '$solvedToday',
                label: locale.get('puzzle_today_short'),
                color: Colors.green,
              ),
            ),
            Expanded(
              child: _RatingItem(
                rating: userRating,
                delta: ratingDelta,
                label: locale.get('puzzle_rating'),
              ),
            ),
            Expanded(
              child: _StatItem(
                icon: Icons.timer,
                value: _formatTime(elapsedSeconds),
                label: locale.get('puzzle_time'),
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingItem extends StatelessWidget {
  final int rating;
  final int? delta;
  final String label;

  const _RatingItem({
    required this.rating,
    this.delta,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.star, color: Colors.purple, size: 20),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$rating',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            if (delta != null) ...[
              const SizedBox(width: 4),
              Text(
                delta! >= 0 ? '+$delta' : '$delta',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: delta! >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ],
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}