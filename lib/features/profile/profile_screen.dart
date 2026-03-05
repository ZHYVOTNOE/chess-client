import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/locale_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(locale.get('profile_title')),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {}, // TODO: редактирование
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {}, // TODO: настройки
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Шапка профиля
            _buildProfileHeader(),
            const SizedBox(height: 16),

            // Рейтинги
            _buildRatingsSection(locale),
            const SizedBox(height: 16),

            // Радар (роза ветров)
            _buildRadarChart(locale),
            const SizedBox(height: 16),

            // История игр
            _buildGameHistory(locale),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey.shade300,
                  child: const Icon(Icons.person, size: 50),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.green,
                    child: const Icon(Icons.check, size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'GrandMaster_2024', // nickname
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Иван Петров', // имя фамилия
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'ID: 12345678',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingsSection(LocaleProvider locale) {
    final ratings = [
      {'mode': 'bullet', 'rating': 1850, 'games': 234, 'icon': Icons.flash_on},
      {'mode': 'blitz', 'rating': 1920, 'games': 567, 'icon': Icons.bolt},
      {'mode': 'rapid', 'rating': 2050, 'games': 123, 'icon': Icons.timer},
      {'mode': 'daily', 'rating': 1980, 'games': 89, 'icon': Icons.schedule},
    ];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              locale.get('profile_ratings'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...ratings.map((r) => _RatingTile(
              mode: r['mode'] as String,
              rating: r['rating'] as int,
              games: r['games'] as int,
              icon: r['icon'] as IconData,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildRadarChart(LocaleProvider locale) {
    // Параметры: тактика, стратегия, эндшпиль, дебюты, расчёт, скорость
    final data = [0.8, 0.7, 0.6, 0.75, 0.85, 0.9];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              locale.get('profile_stats'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: RadarChart(
                RadarChartData(
                  radarShape: RadarShape.polygon,
                  dataSets: [
                    RadarDataSet(
                      dataEntries: data.map((v) => RadarEntry(value: v)).toList(),
                      fillColor: Colors.blue.withOpacity(0.3),
                      borderColor: Colors.blue,
                      entryRadius: 0,
                    ),
                  ],
                  getTitle: (index, angle) {
                    final titles = [
                      locale.get('stat_tactics'),
                      locale.get('stat_strategy'),
                      locale.get('stat_endgame'),
                      locale.get('stat_opening'),
                      locale.get('stat_calculation'),
                      locale.get('stat_speed'),
                    ];
                    return RadarChartTitle(text: titles[index]);
                  },
                  tickCount: 4,
                  ticksTextStyle: const TextStyle(color: Colors.transparent),
                  gridBorderData: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameHistory(LocaleProvider locale) {
    final games = [
      {'result': 'win', 'opponent': 'Player1', 'rating': 1800, 'mode': 'blitz', 'moves': 34},
      {'result': 'loss', 'opponent': 'Player2', 'rating': 1950, 'mode': 'bullet', 'moves': 21},
      {'result': 'draw', 'opponent': 'Player3', 'rating': 1900, 'mode': 'rapid', 'moves': 67},
    ];

    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  locale.get('profile_history'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(locale.get('view_all')),
                ),
              ],
            ),
          ),
          ...games.map((g) => _GameHistoryTile(game: g)),
        ],
      ),
    );
  }
}

class _RatingTile extends StatelessWidget {
  final String mode;
  final int rating;
  final int games;
  final IconData icon;

  const _RatingTile({
    required this.mode,
    required this.rating,
    required this.games,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final modeNames = {
      'bullet': 'Пуля',
      'blitz': 'Блиц',
      'rapid': 'Рапид',
      'daily': 'Заочный',
    };

    return ListTile(
      leading: Icon(icon, color: _getRatingColor(rating)),
      title: Text(modeNames[mode] ?? mode),
      subtitle: Text('$games партий'),
      trailing: Text(
        rating.toString(),
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: _getRatingColor(rating),
        ),
      ),
    );
  }

  Color _getRatingColor(int rating) {
    if (rating < 1200) return Colors.grey;
    if (rating < 1400) return Colors.brown;
    if (rating < 1600) return Colors.green;
    if (rating < 1800) return Colors.blue;
    if (rating < 2000) return Colors.purple;
    if (rating < 2200) return Colors.orange;
    return Colors.red;
  }
}

class _GameHistoryTile extends StatelessWidget {
  final Map<String, dynamic> game;

  const _GameHistoryTile({required this.game});

  @override
  Widget build(BuildContext context) {
    final resultColors = {
      'win': Colors.green,
      'loss': Colors.red,
      'draw': Colors.grey,
    };

    final resultIcons = {
      'win': Icons.add,
      'loss': Icons.remove,
      'draw': Icons.drag_handle,
    };

    final resultTexts = {
      'win': 'Победа',
      'loss': 'Поражение',
      'draw': 'Ничья',
    };

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: resultColors[game['result']]?.withOpacity(0.1),
        child: Icon(
          resultIcons[game['result']],
          color: resultColors[game['result']],
        ),
      ),
      title: Text('${game['opponent']} (${game['rating']})'),
      subtitle: Text('${game['mode']} • ${game['moves']} ходов'),
      trailing: Text(
        resultTexts[game['result']] ?? '',
        style: TextStyle(
          color: resultColors[game['result']],
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}