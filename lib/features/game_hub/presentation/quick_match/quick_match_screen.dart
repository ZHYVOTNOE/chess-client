import 'package:client/features/play/presentation/board_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/game_provider.dart';
import '../../../../core/providers/locale_provider.dart';

class QuickMatchScreen extends StatefulWidget {
  const QuickMatchScreen({super.key});

  @override
  State<QuickMatchScreen> createState() => _QuickMatchScreenState();
}

class _QuickMatchScreenState extends State<QuickMatchScreen> {
  String _selectedTime = '3|0';
  String _ratingRange = '±200';
  bool _rated = true;
  bool _showCustom = false;

  // Базовые контроли по категориям
  final Map<String, List<Map<String, dynamic>>> _timeControls = {
    'bullet': [
      {'code': '0:30|0', 'minutes': 0, 'seconds': 30, 'increment': 0, 'display': '0:30'},
      {'code': '1|0', 'minutes': 1, 'seconds': 0, 'increment': 0, 'display': '1|0'},
      {'code': '1|1', 'minutes': 1, 'seconds': 0, 'increment': 1, 'display': '1|1'},
      {'code': '2|1', 'minutes': 2, 'seconds': 0, 'increment': 1, 'display': '2|1'},
    ],
    'blitz': [
      {'code': '3|0', 'minutes': 3, 'seconds': 0, 'increment': 0, 'display': '3|0'},
      {'code': '3|2', 'minutes': 3, 'seconds': 0, 'increment': 2, 'display': '3|2'},
      {'code': '5|0', 'minutes': 5, 'seconds': 0, 'increment': 0, 'display': '5|0'},
      {'code': '5|3', 'minutes': 5, 'seconds': 0, 'increment': 3, 'display': '5|3'},
    ],
    'rapid': [
      {'code': '10|0', 'minutes': 10, 'seconds': 0, 'increment': 0, 'display': '10|0'},
      {'code': '10|5', 'minutes': 10, 'seconds': 0, 'increment': 5, 'display': '10|5'},
      {'code': '15|10', 'minutes': 15, 'seconds': 0, 'increment': 10, 'display': '15|10'},
      {'code': '30|0', 'minutes': 30, 'seconds': 0, 'increment': 0, 'display': '30|0'},
    ],
  };

  // Кастомные значения
  int _customMinutes = 5;
  int _customSeconds = 0;
  int _customIncrement = 0;

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final gameProvider = context.read<GameProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(locale.get('quick_title')),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle(locale.get('quick_time_control')),
            _buildCategoryTabs(),
            const SizedBox(height: 16),
            _showCustom ? _buildCustomTime() : _buildTimeGrid(),
            const SizedBox(height: 24),

            _buildSectionTitle(locale.get('quick_rating_range')),
            _buildRatingRangeSelector(),
            const SizedBox(height: 24),

            _buildSectionTitle(locale.get('quick_options')),
            _buildOptions(),
            const SizedBox(height: 32),

            _buildSearchButton(locale),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  String _currentCategory = 'blitz';

  Widget _buildCategoryTabs() {
    final categories = [
      {'code': 'bullet', 'name': 'Bullet', 'icon': MdiIcons.bullet},
      {'code': 'blitz', 'name': 'Blitz', 'icon': Icons.bolt},
      {'code': 'rapid', 'name': 'Rapid', 'icon': Icons.timer},
      {'code': 'custom', 'name': 'Custom', 'icon': Icons.tune},
    ];

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _currentCategory == cat['code'];
          final isCustom = cat['code'] == 'custom';

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              avatar: Icon(
                cat['icon'] as IconData,
                size: 18,
                color: isSelected ? Colors.white : Colors.grey,
              ),
              label: Text(cat['name'] as String),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _currentCategory = cat['code'] as String;
                    _showCustom = isCustom;
                    if (!isCustom) {
                      _selectedTime = _timeControls[cat['code']]!.first['code'] as String;
                    }
                  });
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeGrid() {
    final times = _timeControls[_currentCategory] ?? [];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: times.length,
      itemBuilder: (context, index) {
        final time = times[index];
        final isSelected = _selectedTime == time['code'];

        return GestureDetector(
          onTap: () => setState(() => _selectedTime = time['code'] as String),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: Theme.of(context).primaryColor, width: 2)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  time['display'] as String,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  '${time['minutes']}:${(time['seconds'] as int).toString().padLeft(2, '0')} + ${time['increment']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? Colors.white70 : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomTime() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildNumberPicker(
                    label: 'Минуты',
                    value: _customMinutes,
                    onChanged: (v) => setState(() => _customMinutes = v),
                    max: 60,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildNumberPicker(
                    label: 'Секунды',
                    value: _customSeconds,
                    onChanged: (v) => setState(() => _customSeconds = v),
                    max: 59,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildNumberPicker(
                    label: 'Добавление',
                    value: _customIncrement,
                    onChanged: (v) => setState(() => _customIncrement = v),
                    max: 60,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Итого: $_customMinutes:${_customSeconds.toString().padLeft(2, '0')} + $_customIncrement',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberPicker({
    required String label,
    required int value,
    required Function(int) onChanged,
    required int max,
  }) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: value > 0 ? () => onChanged(value - 1) : null,
              iconSize: 20,
            ),
            Text(
              value.toString(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: value < max ? () => onChanged(value + 1) : null,
              iconSize: 20,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingRangeSelector() {
    final ranges = [
      {'code': '±100', 'label': '±100', 'desc': 'Точный поиск'},
      {'code': '±200', 'label': '±200', 'desc': 'Рекомендуется'},
      {'code': '±500', 'label': '±500', 'desc': 'Быстрый поиск'},
      {'code': 'any', 'label': 'Любой', 'desc': 'Без ограничений'},
    ];

    return Column(
      children: ranges.map((range) {
        final isSelected = _ratingRange == range['code'];
        return RadioListTile<String>(
          title: Text(range['label'] as String),
          subtitle: Text(
            range['desc'] as String,
            style: const TextStyle(fontSize: 12),
          ),
          value: range['code'] as String,
          groupValue: _ratingRange,
          onChanged: (value) => setState(() => _ratingRange = value!),
        );
      }).toList(),
    );
  }

  Widget _buildOptions() {
    return SwitchListTile(
      title: const Text('Рейтинговая игра'),
      subtitle: const Text('Результат повлияет на ваш рейтинг'),
      value: _rated,
      onChanged: (value) => setState(() => _rated = value),
    );
  }

  Widget _buildSearchButton(LocaleProvider locale) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          /*final timeCode = _showCustom
              ? '${_customMinutes}:${_customSeconds.toString().padLeft(2, '0')}|$_customIncrement'
              : _selectedTime;

          _showSearchingDialog(context, locale, timeCode);*/
          context.push('/game/play');
        },
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          locale.get('quick_search'),
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }

  void _showSearchingDialog(BuildContext context, LocaleProvider locale, String timeCode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(locale.get('quick_searching')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(timeCode.replaceAll('|', ' + ')),
            Text('$_ratingRange • Случайный цвет'),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(locale.get('cancel')),
            ),
          ],
        ),
      ),
    );
  }
}