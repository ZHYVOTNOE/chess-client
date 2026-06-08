import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/locale_provider.dart';

class JoinLiveTournamentScreen extends StatelessWidget {
  const JoinLiveTournamentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();

    // TODO: загрузка с сервера
    final tournaments = [
      {
        'name': 'Весенняя арена',
        'timeFormat': 'bullet',
        'timeControl': '1|0',
        'format': 'arena',
        'players': 45,
        'maxPlayers': 100,
        'startsIn': '5 мин',
      },
      {
        'name': 'Блиц мастеров',
        'timeFormat': 'blitz',
        'timeControl': '3|2',
        'format': 'swiss',
        'players': 32,
        'maxPlayers': 64,
        'startsIn': '15 мин',
      },
      {
        'name': 'Рапид классика',
        'timeFormat': 'rapid',
        'timeControl': '10|0',
        'format': 'arena',
        'players': 28,
        'maxPlayers': 50,
        'startsIn': '30 мин',
      },
      {
        'name': 'Ночной пулемёт',
        'timeFormat': 'bullet',
        'timeControl': '2|1',
        'format': 'swiss',
        'players': 67,
        'maxPlayers': 128,
        'prize': '1500 ₽',
        'startsIn': '1 ч',
      },
    ];

    return Scaffold(
      body: ListView.builder(
        padding: EdgeInsets.all(16.r),
        itemCount: tournaments.length,
        itemBuilder: (context, index) {
          final t = tournaments[index];
          return _TournamentBlock(
            name: t['name'] as String,
            timeFormat: t['timeFormat'] as String,
            timeControl: t['timeControl'] as String,
            format: t['format'] as String,
            players: t['players'] as int,
            maxPlayers: t['maxPlayers'] as int,
            startsIn: t['startsIn'] as String,
            onJoin: () => _showJoinDialog(context, locale, t),
          );
        },
      ),
    );
  }

  void _showJoinDialog(BuildContext context, LocaleProvider locale, Map<String, dynamic> tournament) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tournament['name'] as String),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${locale.get('time_control')}: ${tournament['timeControl']}'),
            Text('${locale.get('format')}: ${_getFormatName(tournament['format'] as String)}'),
            Text('${locale.get('players')}: ${tournament['players']}/${tournament['maxPlayers']}'),
            SizedBox(height: 16.h),
            Text(
              '${locale.get('starts_in')}: ${tournament['startsIn']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(locale.get('cancel')),
          ),
          FilledButton(
            onPressed: () {
              // TODO: API присоединения
              Navigator.pop(context);
              context.push('/game/tournament/lobby', extra: tournament);
            },
            child: Text(locale.get('join')),
          ),
        ],
      ),
    );
  }

  String _getFormatName(String format) {
    final names = {
      'arena': 'Арена',
      'swiss': 'Швейцарка',
    };
    return names[format] ?? format;
  }
}

class _TournamentBlock extends StatelessWidget {
  final String name;
  final String timeFormat;
  final String timeControl;
  final String format;
  final int players;
  final int maxPlayers;
  final String startsIn;
  final VoidCallback onJoin;

  const _TournamentBlock({
    required this.name,
    required this.timeFormat,
    required this.timeControl,
    required this.format,
    required this.players,
    required this.maxPlayers,
    required this.startsIn,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormatColors = {
      'bullet': Colors.red,
      'blitz': Colors.orange,
      'rapid': Colors.blue,
    };

    final formatIcons = {
      'arena': Icons.sports_score,
      'swiss': Icons.format_list_numbered,
    };

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onJoin,
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Строка 1: Название и приз
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              // Строка 2: Временной формат и контроль
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: (timeFormatColors[timeFormat] ?? Colors.grey).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      _getTimeFormatName(timeFormat),
                      style: TextStyle(
                        color: timeFormatColors[timeFormat] ?? Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Icon(Icons.timer, size: 16.r, color: Colors.grey.shade600),
                  SizedBox(width: 4.w),
                  Text(
                    timeControl,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  // Начало через
                  Icon(Icons.schedule, size: 16.r, color: Colors.grey.shade600),
                  SizedBox(width: 4.w),
                  Text(
                    'Через $startsIn',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              // Строка 3: Тип турнира и участники
              Row(
                children: [
                  Icon(
                    formatIcons[format] ?? Icons.help,
                    size: 20.r,
                    color: Theme.of(context).primaryColor,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    _getFormatName(format),
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.people, size: 16.r, color: Colors.grey.shade600),
                  SizedBox(width: 4.w),
                  Text(
                    '$players / $maxPlayers',
                    style: TextStyle(
                      color: players >= maxPlayers * 0.9
                          ? Colors.red
                          : Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              // Индикатор заполненности
              SizedBox(height: 12.h),
              LinearProgressIndicator(
                value: players / maxPlayers,
                backgroundColor: Colors.grey.shade200,
                color: players >= maxPlayers * 0.9 ? Colors.red : Colors.green,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeFormatName(String format) {
    final names = {
      'bullet': 'ПУЛЯ',
      'blitz': 'БЛИЦ',
      'rapid': 'РАПИД',
    };
    return names[format] ?? format.toUpperCase();
  }

  String _getFormatName(String format) {
    final names = {
      'arena': 'Арена',
      'swiss': 'Швейцарка',
    };
    return names[format] ?? format;
  }
}