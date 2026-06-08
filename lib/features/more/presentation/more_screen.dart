import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/locale_provider.dart';
import '../../social/presentation/cubits/social_cubit.dart';

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
      {'icon': Icons.help_outline, 'title': 'more_help', 'route': '/more/support'},
      {'icon': Icons.query_stats, 'title': 'more_stats', 'route': '/more/stats'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(locale.get('more_title')),
        centerTitle: true,
      ),
      body: BlocBuilder<SocialCubit, SocialState>(
        builder: (context, socialState) {
          return GridView.builder(
            padding: EdgeInsets.all(16.r),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.8,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];

              // Для большинства кнопок берём статичный бэйдж из items
              int? badge = item['badge'] as int?;

              // Для друзей — динамический из SocialCubit
              if (item['route'] == '/more/friends') {
                badge = socialState.pendingRequestsCount > 0
                    ? socialState.pendingRequestsCount
                    : null;
              }

              return _MoreButton(
                icon: item['icon'] as IconData,
                title: locale.get(item['title'] as String),
                route: item['route'] as String,
                badge: badge,
                onTap: () => context.push(item['route'] as String),
              );
            },
          );
        },
      ),
    );
  }
}

// _MoreButton без изменений
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
                  Icon(icon, size: 32.r, color: Theme.of(context).primaryColor),
                  SizedBox(height: 8.h),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.sp),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (badge != null)
              Positioned(
                top: 8.r,
                right: 8.r,
                child: Container(
                  padding: EdgeInsets.all(4.r),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: BoxConstraints(minWidth: 20.r, minHeight: 20.r),
                  child: Text(
                    badge.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.sp,
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