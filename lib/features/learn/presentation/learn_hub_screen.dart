import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/locale_provider.dart';

class LearnHubScreen extends StatelessWidget {
  const LearnHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(locale.get('learn_title')),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Верхний ряд: Задачи + Дебюты
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _LearnCard(
                      icon: Icons.extension,
                      title: locale.get('learn_puzzles'),
                      subtitle: locale.get('learn_puzzles_desc'),
                      color: Colors.green,
                      onTap: () => context.push('/learn/puzzles'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _LearnCard(
                      icon: Icons.open_in_full,
                      title: locale.get('learn_openings'),
                      subtitle: locale.get('learn_openings_desc'),
                      color: Colors.blue,
                      onTap: () => context.push('/learn/openings'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Нижний ряд: Стратегия + Эндшпили
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _LearnCard(
                      icon: Icons.psychology,
                      title: locale.get('learn_strategy'),
                      subtitle: locale.get('learn_strategy_desc'),
                      color: Colors.orange,
                      onTap: () => context.push('/learn/strategy'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _LearnCard(
                      icon: Icons.flag,
                      title: locale.get('learn_endgames'),
                      subtitle: locale.get('learn_endgames_desc'),
                      color: Colors.purple,
                      onTap: () => context.push('/learn/endgames'),
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

class _LearnCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _LearnCard({
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
                    fontSize: 18,
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