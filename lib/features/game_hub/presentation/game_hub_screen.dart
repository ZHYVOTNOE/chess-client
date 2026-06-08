import 'package:client/core/providers/game_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/locale_provider.dart';

class GameHubScreen extends StatelessWidget {
  const GameHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final gameProvider = context.read<GameProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(locale.get('game_title')),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.r),
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
                      onTap: () {
                        print(MediaQuery.of(context).size.width);
                        print(MediaQuery.of(context).size.height);
                        gameProvider.setVsRandom(value: true);
                        gameProvider.setVsFriend(value: false);
                        gameProvider.setVsComputer(value: false);
                        context.push('/game/setup/random');
                      },
                    ),
                  ),
                  SizedBox(width: 16.w),
                  // Игра с другом
                  Expanded(
                    child: _GameModeCard(
                      icon: Icons.people,
                      title: locale.get('game_friend'),
                      subtitle: locale.get('game_friend_subtitle'),
                      color: Colors.blue,
                      onTap: () {
                        gameProvider.setVsRandom(value: false);
                        gameProvider.setVsFriend(value: true);
                        gameProvider.setVsComputer(value: false);
                        context.push('/game/setup/friend');
                      },
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            Expanded(
              child: Row(
                children: [
                  // Игра с ботом
                  Expanded(
                    child: _GameModeCard(
                      icon: Icons.smart_toy,
                      title: locale.get('game_bot'),
                      subtitle: locale.get('game_bot_subtitle'),
                      color: Colors.green,
                      onTap: () {
                        gameProvider.setVsRandom(value: false);
                        gameProvider.setVsFriend(value: false);
                        gameProvider.setVsComputer(value: true);
                        context.push('/game/setup/computer');
                      },
                    ),
                  ),
                  SizedBox(width: 16.w),
                  // Локальная игра
                  Expanded(
                    child: _GameModeCard(
                      icon: Icons.devices,
                      title: 'Local Play',
                      subtitle: 'Two players on one device',
                      color: Colors.purple,
                      onTap: () {
                        gameProvider.setVsRandom(value: false);
                        gameProvider.setVsFriend(value: false);
                        gameProvider.setVsComputer(value: false);
                        context.push('/game/setup/local');
                      },
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
            padding: EdgeInsets.all(16.r),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 48.r,
                  color: Colors.white,
                ),
                SizedBox(height: 12.h),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.sp,
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