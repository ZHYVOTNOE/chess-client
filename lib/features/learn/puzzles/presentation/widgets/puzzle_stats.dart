import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:client/core/providers/locale_provider.dart';

class PuzzleStats extends StatelessWidget {
  final int streak;
  final int solvedToday;
  final int progress;

  const PuzzleStats({
    super.key,
    this.streak = 0,
    this.solvedToday = 0,
    this.progress = 0,
  });

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: _StatItem(
                icon: Icons.local_fire_department,
                value: '$streak',
                label: locale.get('puzzles_streak'),
                color: Colors.orange,
              ),
            ),
            Expanded(
              child: _StatItem(
                icon: Icons.check_circle,
                value: '$solvedToday',
                label: locale.get('puzzles_solved_today'),
                color: Colors.green,
              ),
            ),
            Expanded(
              child: _StatItem(
                icon: Icons.trending_up,
                value: progress >= 0 ? '+$progress' : '$progress',
                label: locale.get('puzzles_progress'),
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
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
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
