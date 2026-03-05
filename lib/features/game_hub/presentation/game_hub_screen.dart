import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/locale_provider.dart';

class GameHubScreen extends StatelessWidget {
  const GameHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  // Быстрая игра
                  Expanded(
                    child: _GameModeCard(
                      icon: Icons.bolt,
                      title: locale.get('game_quick'),
                      subtitle: locale.get('game_quick_subtitle'),
                      color: Colors.orange,
                      onTap: () => context.push('/game/quick'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Турниры
                  Expanded(
                    child: _GameModeCard(
                      icon: Icons.emoji_events,
                      title: locale.get('game_tournament'),
                      subtitle: locale.get('game_tournament_subtitle'),
                      color: Colors.purple,
                      onTap: () => context.push('/game/tournament'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                children: [
                  // Игра с другом
                  Expanded(
                    child: _GameModeCard(
                      icon: Icons.people,
                      title: locale.get('game_friend'),
                      subtitle: locale.get('game_friend_subtitle'),
                      color: Colors.blue,
                      onTap: () => context.push('/game/friend'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Игра с ботом
                  Expanded(
                    child: _GameModeCard(
                      icon: Icons.smart_toy,
                      title: locale.get('game_bot'),
                      subtitle: locale.get('game_bot_subtitle'),
                      color: Colors.green,
                      onTap: () => context.push('/game/bot'),
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

class _GameModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _GameModeCard({
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
              colors: [
                color,
                color.withOpacity(0.7),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
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