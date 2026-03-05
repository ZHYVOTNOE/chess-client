import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/locale_provider.dart';

class JoinDailyTournamentScreen extends StatelessWidget {
  const JoinDailyTournamentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();

    final tournaments = [
      {
        'name': 'Олимпийский марафон',
        'timePerMove': 3,
        'format': 'olympic',
        'players': 16,
        'maxPlayers': 16,
        'startsInDays': 2,
        'rounds': 4, // 1/8, 1/4, 1/2, финал
      },
      {
        'name': 'Групповой чемпионат',
        'timePerMove': 1,
        'format': 'groups',
        'players': 32,
        'maxPlayers': 32,
        'startsInDays': 5,
        'groups': 4,
        'advancing': 2,
      },
      {
        'name': 'Кубок вызова',
        'timePerMove': 5,
        'format': 'olympic',
        'players': 8,
        'maxPlayers': 8,
        'startsInDays': 0,
        'rounds': 3,
      },
      {
        'name': 'Лига чемпионов',
        'timePerMove': 2,
        'format': 'groups',
        'players': 64,
        'maxPlayers': 64,
        'startsInDays': 14,
        'groups': 8,
        'advancing': 2,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(locale.get('tournament_join_daily_title')),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tournaments.length,
        itemBuilder: (context, index) {
          final t = tournaments[index];
          return _DailyTournamentBlock(
            name: t['name'] as String,
            timePerMove: t['timePerMove'] as int,
            format: t['format'] as String,
            players: t['players'] as int,
            maxPlayers: t['maxPlayers'] as int,
            startsInDays: t['startsInDays'] as int,
            rounds: t['rounds'] as int?,
            groups: t['groups'] as int?,
            advancing: t['advancing'] as int?,
            onJoin: () => _showJoinDialog(context, locale, t),
          );
        },
      ),
    );
  }

  void _showJoinDialog(BuildContext context, LocaleProvider locale, Map<String, dynamic> tournament) {
    final startsIn = tournament['startsInDays'] as int;
    final format = tournament['format'] as String;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tournament['name'] as String),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${locale.get('time_per_move')}: ${tournament['timePerMove']} ${locale.get('days')}'),
            Text('${locale.get('format')}: ${_getFormatName(format)}'),
            if (format == 'olympic' && tournament['rounds'] != null)
              Text('${locale.get('rounds')}: ${tournament['rounds']}'),
            if (format == 'groups') ...[
              Text('${locale.get('groups')}: ${tournament['groups']}'),
              Text('${locale.get('advancing')}: ${tournament['advancing']} ${locale.get('from_each_group')}'),
            ],
            Text('${locale.get('players')}: ${tournament['players']}/${tournament['maxPlayers']}'),
            const SizedBox(height: 16),
            Text(
              startsIn == 0
                  ? locale.get('starts_today')
                  : '${locale.get('starts_in')}: $startsIn ${_getDayWord(startsIn)}',
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
              Navigator.pop(context);
              context.push('/game/tournament/daily-lobby', extra: tournament);
            },
            child: Text(locale.get('join')),
          ),
        ],
      ),
    );
  }

  String _getFormatName(String format) {
    final names = {
      'olympic': 'Олимпийская система',
      'groups': 'Групповой этап',
    };
    return names[format] ?? format;
  }

  String _getDayWord(int days) {
    if (days % 10 == 1 && days % 100 != 11) return 'день';
    if ([2, 3, 4].contains(days % 10) && ![12, 13, 14].contains(days % 100)) return 'дня';
    return 'дней';
  }
}

class _DailyTournamentBlock extends StatelessWidget {
  final String name;
  final int timePerMove;
  final String format;
  final int players;
  final int maxPlayers;
  final int startsInDays;
  final int? rounds;
  final int? groups;
  final int? advancing;
  final VoidCallback onJoin;

  const _DailyTournamentBlock({
    required this.name,
    required this.timePerMove,
    required this.format,
    required this.players,
    required this.maxPlayers,
    required this.startsInDays,
    this.rounds,
    this.groups,
    this.advancing,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final formatIcons = {
      'olympic': Icons.emoji_events,
      'groups': Icons.grid_view,
    };

    final formatColors = {
      'olympic': Colors.amber,
      'groups': Colors.blue,
    };

    final timeColor = timePerMove <= 1
        ? Colors.orange
        : timePerMove <= 3
        ? Colors.blue
        : Colors.purple;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onJoin,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Строка 1: Название и иконка формата
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  CircleAvatar(
                    backgroundColor: (formatColors[format] ?? Colors.grey).withOpacity(0.2),
                    child: Icon(
                      formatIcons[format] ?? Icons.help,
                      color: formatColors[format] ?? Colors.grey,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Строка 2: Время на ход и до старта
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: timeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$timePerMove ${timePerMove == 1 ? 'день' : 'дня'} на ход',
                      style: TextStyle(
                        color: timeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.event, size: 16, color: startsInDays == 0 ? Colors.green : Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    startsInDays == 0
                        ? 'Начинается сегодня'
                        : 'Через $startsInDays ${_getDayWord(startsInDays)}',
                    style: TextStyle(
                      color: startsInDays == 0 ? Colors.green : Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: startsInDays == 0 ? FontWeight.bold : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Строка 3: Формат и участники
              Row(
                children: [
                  Text(
                    _getFormatName(format),
                    style: TextStyle(
                      color: formatColors[format] ?? Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (format == 'olympic' && rounds != null)
                    Text(
                      '• $rounds ${_getRoundWord(rounds!)}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  if (format == 'groups' && groups != null) ...[
                    Text(
                      '• $groups ${_getGroupWord(groups!)}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    if (advancing != null)
                      Text(
                        ', $advancing ${_getAdvancingWord(advancing!)}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                  ],
                  const Spacer(),
                  Icon(Icons.people, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '$players / $maxPlayers',
                    style: TextStyle(
                      color: players >= maxPlayers ? Colors.red : Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              // Индикатор заполненности
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: players / maxPlayers,
                backgroundColor: Colors.grey.shade200,
                color: players >= maxPlayers ? Colors.red : Colors.green,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getFormatName(String format) {
    final names = {
      'olympic': 'На выбывание',
      'groups': 'Групповой этап',
    };
    return names[format] ?? format;
  }

  String _getDayWord(int days) {
    if (days % 10 == 1 && days % 100 != 11) return 'день';
    if ([2, 3, 4].contains(days % 10) && ![12, 13, 14].contains(days % 100)) return 'дня';
    return 'дней';
  }

  String _getRoundWord(int rounds) {
    if (rounds % 10 == 1 && rounds % 100 != 11) return 'раунд';
    if ([2, 3, 4].contains(rounds % 10) && ![12, 13, 14].contains(rounds % 100)) return 'раунда';
    return 'раундов';
  }

  String _getGroupWord(int groups) {
    if (groups % 10 == 1 && groups % 100 != 11) return 'группа';
    if ([2, 3, 4].contains(groups % 10) && ![12, 13, 14].contains(groups % 100)) return 'группы';
    return 'групп';
  }

  String _getAdvancingWord(int count) {
    if (count % 10 == 1 && count % 100 != 11) return 'проходит';
    return 'проходят';
  }
}