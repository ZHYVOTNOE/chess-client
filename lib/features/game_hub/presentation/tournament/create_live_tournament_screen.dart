import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/locale_provider.dart';

class CreateLiveTournamentScreen extends StatefulWidget {
  const CreateLiveTournamentScreen({super.key});

  @override
  State<CreateLiveTournamentScreen> createState() => _CreateLiveTournamentScreenState();
}

class _CreateLiveTournamentScreenState extends State<CreateLiveTournamentScreen> {
  final _nameController = TextEditingController();
  final _customPositionController = TextEditingController();

  String _timeControl = '3|0';
  String _format = 'arena';
  int _maxPlayers = 16;
  String _ratingRange = 'any';
  DateTime _startTime = DateTime.now().add(const Duration(hours: 1));
  String _timeZone = 'UTC+3';
  String _startingPosition = 'standard';

  final List<String> _timeControls = ['1|0', '2|1', '3|0', '3|2', '5|0', '5|3', '10|0', '10|5'];
  final List<int> _playerCounts = [4, 8, 16, 32, 64, 128];
  final List<String> _ratingRanges = ['any', '±100', '±200', '±500'];
  final List<String> _timeZones = ['UTC', 'UTC+1', 'UTC+2', 'UTC+3', 'UTC+4', 'UTC+5', 'UTC-5', 'UTC-8'];

  @override
  void dispose() {
    _nameController.dispose();
    _customPositionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(locale.get('tournament_create_live_title')),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Название
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: locale.get('tournament_name'),
                prefixIcon: const Icon(Icons.title),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Тип турнира
            _buildSectionTitle(locale.get('tournament_format')),
            _buildFormatSelector(),
            const SizedBox(height: 24),

            // Временной контроль
            _buildSectionTitle(locale.get('time_control')),
            _buildTimeControlSelector(),
            const SizedBox(height: 24),

            // Количество участников
            _buildSectionTitle(locale.get('max_players')),
            _buildPlayerCountSelector(),
            const SizedBox(height: 24),

            // Диапазон рейтинга
            _buildSectionTitle(locale.get('rating_range')),
            _buildRatingRangeSelector(),
            const SizedBox(height: 24),

            // Дата и время начала
            _buildSectionTitle(locale.get('start_time')),
            _buildDateTimeSelector(),
            const SizedBox(height: 24),

            // Начальная позиция
            _buildSectionTitle(locale.get('starting_position')),
            _buildPositionSelector(),
            const SizedBox(height: 32),

            // Кнопка создания
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _createTournament,
                child: Text(locale.get('create_tournament'), style: const TextStyle(fontSize: 18)),
              ),
            ),
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
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }

  Widget _buildFormatSelector() {
    final formats = [
      {'code': 'arena', 'name': 'Арена', 'icon': Icons.sports_score, 'desc': 'Все играют со всеми'},
      {'code': 'swiss', 'name': 'Швейцарка', 'icon': Icons.format_list_numbered, 'desc': 'Раунды по рейтингу'},
    ];

    return Row(
      children: formats.map((f) {
        final isSelected = _format == f['code'];
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _format = f['code'] as String),
            child: Card(
              color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Icon(f['icon'] as IconData,
                        color: isSelected ? Theme.of(context).primaryColor : Colors.grey),
                    const SizedBox(height: 8),
                    Text(f['name'] as String,
                        style: TextStyle(fontWeight: isSelected ? FontWeight.bold : null)),
                    Text(f['desc'] as String,
                        style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimeControlSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _timeControls.map((time) {
        final isSelected = _timeControl == time;
        return ChoiceChip(
          label: Text(time.replaceAll('|', '+')),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) setState(() => _timeControl = time);
          },
        );
      }).toList(),
    );
  }

  Widget _buildPlayerCountSelector() {
    return Wrap(
      spacing: 12,
      children: _playerCounts.map((count) {
        final isSelected = _maxPlayers == count;
        return ChoiceChip(
          label: Text('$count'),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) setState(() => _maxPlayers = count);
          },
        );
      }).toList(),
    );
  }

  Widget _buildRatingRangeSelector() {
    return Column(
      children: _ratingRanges.map((range) {
        final isSelected = _ratingRange == range;
        return RadioListTile<String>(
          title: Text(range == 'any' ? 'Любой рейтинг' : '±$range от твоего'),
          value: range,
          groupValue: _ratingRange,
          onChanged: (v) => setState(() => _ratingRange = v!),
        );
      }).toList(),
    );
  }

  Widget _buildDateTimeSelector() {
    return Column(
      children: [
        // Выбор даты и времени
        ListTile(
          leading: const Icon(Icons.calendar_today),
          title: Text(DateFormat('dd.MM.yyyy HH:mm').format(_startTime)),
          subtitle: const Text('Нажмите для изменения'),
          onTap: _pickDateTime,
        ),
        // Часовой пояс
        DropdownButtonFormField<String>(
          value: _timeZone,
          decoration: const InputDecoration(
            labelText: 'Часовой пояс',
            prefixIcon: Icon(Icons.public),
          ),
          items: _timeZones.map((tz) {
            return DropdownMenuItem(value: tz, child: Text(tz));
          }).toList(),
          onChanged: (v) => setState(() => _timeZone = v!),
        ),
      ],
    );
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startTime),
    );
    if (time == null) return;

    setState(() {
      _startTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Widget _buildPositionSelector() {
    final positions = [
      {'code': 'standard', 'name': 'Стандартная', 'fen': 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1'},
      {'code': 'custom', 'name': 'Своя позиция (FEN)', 'fen': ''},
    ];

    return Column(
      children: [
        ...positions.take(3).map((p) => RadioListTile<String>(
          title: Text(p['name'] as String),
          value: p['code'] as String,
          groupValue: _startingPosition,
          onChanged: (v) => setState(() => _startingPosition = v!),
        )),
        RadioListTile<String>(
          title: const Text('Своя позиция'),
          value: 'custom',
          groupValue: _startingPosition,
          onChanged: (v) => setState(() => _startingPosition = v!),
        ),
        if (_startingPosition == 'custom')
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: TextField(
              controller: _customPositionController,
              decoration: const InputDecoration(
                hintText: 'Вставьте FEN',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ),
      ],
    );
  }

  void _createTournament() {
    // TODO: валидация и отправка на сервер

    final tournament = {
      'name': _nameController.text,
      'format': _format,
      'timeControl': _timeControl,
      'maxPlayers': _maxPlayers,
      'ratingRange': _ratingRange,
      'startTime': _startTime.toIso8601String(),
      'timeZone': _timeZone,
      'startingPosition': _startingPosition == 'custom'
          ? _customPositionController.text
          : _startingPosition,
    };

    // Показать код для приглашения
    _showSuccessDialog(tournament);
  }

  void _showSuccessDialog(Map<String, dynamic> tournament) {
    final code = 'LIVE' + DateTime.now().millisecondsSinceEpoch.toString().substring(8, 13);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Турнир создан!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            Text(tournament['name']),
            const SizedBox(height: 16),
            const Text('Код турнира:', style: TextStyle(color: Colors.grey)),
            SelectableText(
              code,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 4),
            ),
            const SizedBox(height: 8),
            Text(
              'Начало: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.parse(tournament['startTime']))} ${tournament['timeZone']}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/game/tournament');
            },
            child: const Text('Готово'),
          ),
        ],
      ),
    );
  }
}