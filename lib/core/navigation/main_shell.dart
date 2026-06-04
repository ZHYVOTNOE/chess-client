import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../providers/locale_provider.dart';
import '../../features/social/presentation/cubits/social_cubit.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: navigationShell.goBranch,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: locale.get('nav_home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.sports_esports_outlined),
            selectedIcon: const Icon(Icons.sports_esports),
            label: locale.get('nav_game'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.school_outlined),
            selectedIcon: const Icon(Icons.school),
            label: locale.get('nav_learn'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outlined),
            selectedIcon: const Icon(Icons.person),
            label: locale.get('nav_profile'),
          ),
          BlocBuilder<SocialCubit, SocialState>(
            builder: (context, state) {
              final totalBadge = state.pendingRequestsCount; // + другие счётчики когда появятся
              return NavigationDestination(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.more_horiz_outlined),
                    if (totalBadge > 0)
                      Positioned(
                        right: -8, top: -8,
                        child: _BadgeWidget(count: totalBadge),
                      ),
                  ],
                ),
                selectedIcon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.more_horiz),
                    if (totalBadge > 0)
                      Positioned(
                        right: -8, top: -8,
                        child: _BadgeWidget(count: totalBadge),
                      ),
                  ],
                ),
                label: locale.get('nav_more'),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BadgeWidget extends StatelessWidget {
  final int count;
  const _BadgeWidget({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }
}