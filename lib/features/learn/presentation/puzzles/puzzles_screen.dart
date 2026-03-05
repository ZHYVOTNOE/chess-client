import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/locale_provider.dart';

class PuzzlesScreen extends StatefulWidget {
  const PuzzlesScreen({super.key});

  @override
  State<PuzzlesScreen> createState() => _PuzzlesScreenState();
}

class _PuzzlesScreenState extends State<PuzzlesScreen> {
  String _selectedTheme = 'all';
  int _rating = 1500;
  int _streak = 0;
  int _solvedToday = 12;

  // Текущая задача (заглушка)
  final _currentPuzzle = {
    'fen': 'r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 0 1',
    'solution': ['Nf3', 'Nc6', 'Bb5'],
    'theme': 'Вилка',
    'rating': 1450,
  };

  final List<Map<String, dynamic>> _themes = [
    {'code': 'all', 'name': 'Все темы', 'icon': Icons.category, 'count': 5000},
    {'code': 'fork', 'name': 'Вилка', 'icon': Icons.call_split, 'count': 450},
    {'code': 'pin', 'name': 'Связка', 'icon': Icons.link, 'count': 380},
    {'code': 'skewer', 'name': 'Шкворень', 'icon': Icons.arrow_forward, 'count': 320},
    {'code': 'discovered', 'name': 'Открытый удар', 'icon': Icons.flash_on, 'count': 290},
    {'code': 'mate1', 'name': 'Мат в 1', 'icon': Icons.check_circle, 'count': 150},
    {'code': 'mate2', 'name': 'Мат в 2', 'icon': Icons.check_circle_outline, 'count': 420},
    {'code': 'mate3', 'name': 'Мат в 3', 'icon': Icons.check_box, 'count': 380},
    {'code': 'endgame', 'name': 'Эндшпиль', 'icon': Icons.grid_4x4, 'count': 560},
    {'code': 'middlegame', 'name': 'Миттельшпиль', 'icon': Icons.grid_3x3, 'count': 890},
  ];

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(locale.get('puzzles_title')),
        centerTitle: true,
        actions: [
          // Рейтинг задач
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  const Icon(Icons.extension, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '$_rating',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Статистика дня
          _buildDailyStats(),
          const SizedBox(height: 16),

          // Выбор темы
          _buildThemeSelector(),
          const SizedBox(height: 16),

          // Доска с задачей
          Expanded(
            child: _buildPuzzleBoard(),
          ),

          // Кнопки под доской
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildDailyStats() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(
              icon: Icons.local_fire_department,
              value: '$_streak',
              label: 'Серия',
              color: Colors.orange,
            ),
            _StatItem(
              icon: Icons.check_circle,
              value: '$_solvedToday',
              label: 'Решено сегодня',
              color: Colors.green,
            ),
            _StatItem(
              icon: Icons.trending_up,
              value: '+45',
              label: 'Прогресс',
              color: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSelector() {
    final selectedThemeName = _themes.firstWhere((t) => t['code'] == _selectedTheme)['name'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Тема: $selectedThemeName',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              TextButton(
                onPressed: _showThemePicker,
                child: const Text('Изменить'),
              ),
            ],
          ),
          if (_selectedTheme != 'all')
            Chip(
              label: Text(_themes.firstWhere((t) => t['code'] == _selectedTheme)['name'] as String),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () => setState(() => _selectedTheme = 'all'),
            ),
        ],
      ),
    );
  }

  void _showThemePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Выберите тему',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _themes.length,
                itemBuilder: (context, index) {
                  final theme = _themes[index];
                  final isSelected = _selectedTheme == theme['code'];

                  return ListTile(
                    leading: Icon(theme['icon'] as IconData),
                    title: Text(theme['name'] as String),
                    subtitle: Text('${theme['count']} задач'),
                    trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
                    onTap: () {
                      setState(() => _selectedTheme = theme['code'] as String);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPuzzleBoard() {
    // TODO: интеграция с шахматной доской
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          color: Colors.brown.shade100,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.grid_4x4, size: 64, color: Colors.brown),
                const SizedBox(height: 16),
                Text(
                  'Ход белых',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Найдите лучший ход',
                  style: TextStyle(color: Colors.brown.shade600),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Тема: ${_currentPuzzle['theme']}',
                    style: TextStyle(
                      color: Colors.amber.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _getHint,
              icon: const Icon(Icons.lightbulb_outline),
              label: const Text('Подсказка'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _submitMove,
              icon: const Icon(Icons.check),
              label: const Text('Сделать ход', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _getHint() {
    // TODO: показать подсказку
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Подсказка: Обратите внимание на незащищённого коня')),
    );
  }

  void _submitMove() {
    // TODO: проверка хода
    _showResultDialog(true); // или false
  }

  void _showResultDialog(bool correct) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(
          correct ? Icons.check_circle : Icons.cancel,
          color: correct ? Colors.green : Colors.red,
          size: 64,
        ),
        title: Text(correct ? 'Правильно!' : 'Неправильно'),
        content: correct
            ? const Text('Отличная работа! Переходим к следующей задаче.')
            : const Text('Попробуйте ещё раз или посмотрите решение.'),
        actions: [
          if (!correct)
            TextButton(
              onPressed: () {
                // TODO: показать решение
                Navigator.pop(context);
              },
              child: const Text('Показать решение'),
            ),
          FilledButton(
            onPressed: () {
              setState(() {
                if (correct) {
                  _streak++;
                  _solvedToday++;
                  _rating += 5;
                } else {
                  _streak = 0;
                }
              });
              Navigator.pop(context);
              // TODO: загрузить следующую задачу
            },
            child: Text(correct ? 'Дальше' : 'Попробовать снова'),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}