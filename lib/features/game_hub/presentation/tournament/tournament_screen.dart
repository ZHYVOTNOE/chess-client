import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/locale_provider.dart';

class TournamentScreen extends StatelessWidget {
  const TournamentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Живые турниры (онлайн)
            Expanded(
              child: Row(
                children: [
                  // Присоединиться к живому
                  Expanded(
                    child: _TournamentActionCard(
                      icon: Icons.sensors,
                      title: locale.get('tournament_join_live'),
                      subtitle: locale.get('tournament_live_desc'),
                      color: Colors.green,
                      onTap: () => context.push('/game/tournament/join-live'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Создать живой
                  Expanded(
                    child: _TournamentActionCard(
                      icon: Icons.videocam,
                      title: locale.get('tournament_create_live'),
                      subtitle: locale.get('tournament_create_live_desc'),
                      color: Colors.orange,
                      onTap: () => context.push('/game/tournament/create-live'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Заочные турниры (дни на ход)
            Expanded(
              child: Row(
                children: [
                  // Присоединиться к заочному
                  Expanded(
                    child: _TournamentActionCard(
                      icon: Icons.schedule,
                      title: locale.get('tournament_join_daily'),
                      subtitle: locale.get('tournament_daily_desc'),
                      color: Colors.blue,
                      onTap: () => context.push('/game/tournament/join-daily'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Создать заочный
                  Expanded(
                    child: _TournamentActionCard(
                      icon: Icons.edit_calendar,
                      title: locale.get('tournament_create_daily'),
                      subtitle: locale.get('tournament_create_daily_desc'),
                      color: Colors.purple,
                      onTap: () => context.push('/game/tournament/create-daily'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TournamentActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _TournamentActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, color.withOpacity(0.7)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 48, color: Colors.white),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}