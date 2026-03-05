import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/locale_provider.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();

    final items = [
      {'icon': Icons.settings, 'title': 'more_settings', 'route': '/more/settings'},
      {'icon': Icons.mail, 'title': 'more_inbox', 'route': '/more/inbox', 'badge': 3},
      {'icon': Icons.people, 'title': 'more_friends', 'route': '/more/friends'},
      {'icon': Icons.analytics, 'title': 'more_analysis', 'route': '/more/analysis'},
      {'icon': Icons.emoji_events, 'title': 'more_leaderboard', 'route': '/more/leaderboard'},
      {'icon': Icons.folder_open, 'title': 'more_games', 'route': '/more/games'},
      {'icon': Icons.article, 'title': 'more_news', 'route': '/more/news', 'badge': 1},
      {'icon': Icons.shopping_cart, 'title': 'more_shop', 'route': '/more/shop'},
      {'icon': Icons.military_tech, 'title': 'more_achievements', 'route': '/more/achievements'},
      {'icon': Icons.explore, 'title': 'more_quests', 'route': '/more/quests', 'badge': 5},
      {'icon': Icons.help_outline, 'title': 'more_help', 'route': '/more/help'},
      {'icon': Icons.info_outline, 'title': 'more_about', 'route': '/more/about'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(locale.get('more_title')),
        centerTitle: true,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.8,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _MoreButton(
            icon: item['icon'] as IconData,
            title: locale.get(item['title'] as String),
            route: item['route'] as String,
            badge: item['badge'] as int?,
            onTap: () => context.push(item['route'] as String),
          );
        },
      ),
    );
  }
}

class _MoreButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String route;
  final int? badge;
  final VoidCallback onTap;

  const _MoreButton({
    required this.icon,
    required this.title,
    required this.route,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 32,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (badge != null)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                  child: Text(
                    badge.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}