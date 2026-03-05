import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/locale_provider.dart';

class CreateDailyTournamentScreen extends StatefulWidget {
  const CreateDailyTournamentScreen({super.key});

  @override
  State<CreateDailyTournamentScreen> createState() => _CreateDailyTournamentScreenState();
}

class _CreateDailyTournamentScreenState extends State<CreateDailyTournamentScreen> {
  final _nameController = TextEditingController();
  final _customPositionController = TextEditingController();

  int _daysPerMove = 1;
  String _format = 'groups';
  int _maxPlayers = 16;
  int? _groupsCount;
  int? _advancingCount;
  DateTime _startTime = DateTime.now().add(const Duration(days: 3));
  String _timeZone = 'UTC+3';
  String _startingPosition = 'standard';

  final List<int> _daysOptions = [1, 2, 3, 5, 7, 14];
  final List<int> _playerCounts = [4, 8, 16, 32, 64];
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
        title: Text(locale.get('tournament_create_daily_title')),
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

            // Время на ход
            _buildSectionTitle(locale.get('days_per_move')),
            _buildDaysSelector(),
            const SizedBox(height: 24),

            // Количество участников
            _buildSectionTitle(locale.get('max_players')),
            _buildPlayerCountSelector(),
            const SizedBox(height: 24),

            // Настройки формата
            if (_format == 'groups') ...[
              _buildSectionTitle(locale.get('groups_settings')),
              _buildGroupsSettings(),
              const SizedBox(height: 24),
            ],

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
      {
        'code': 'groups',
        'name': 'Групповой этап',
        'icon': Icons.grid_view,
        'desc': 'Группы, лучшие проходят дальше',
      },
      {
        'code': 'olympic',
        'name': 'Олимпийский',
        'icon': Icons.emoji_events,
        'desc': 'На выбывание, 2/4/8/16 игроков',
      },
    ];

    return Row(
      children: formats.map((f) {
        final isSelected = _format == f['code'];
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _format = f['code'] as String;
                // Сброс настроек при смене формата
                if (_format == 'olympic') {
                  _groupsCount = null;
                  _advancingCount = null;
                  // Округляем до степени 2
                  _maxPlayers = _roundToPowerOf2(_maxPlayers);
                }
              });
            },
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
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  int _roundToPowerOf2(int n) {
    final powers = [4, 8, 16, 32, 64];
    return powers.firstWhere((p) => p >= n, orElse: () => 64);
  }

  Widget _buildDaysSelector() {
    return Wrap(
      spacing: 12,
      children: _daysOptions.map((days) {
        final isSelected = _daysPerMove == days;
        return ChoiceChip(
          label: Text('$days ${days == 1 ? 'день' : 'дня'}'),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) setState(() => _daysPerMove = days);
          },
        );
      }).toList(),
    );
  }

  Widget _buildPlayerCountSelector() {
    // Для олимпийского только степени 2
    final counts = _format == 'olympic'
        ? [4, 8, 16, 32, 64]
        : _playerCounts;

    return Wrap(
      spacing: 12,
      children: counts.map((count) {
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

  Widget _buildGroupsSettings() {
    return Column(
      children: [
        // Количество групп
        DropdownButtonFormField<int>(
          value: _groupsCount ?? 4,
          decoration: const InputDecoration(
            labelText: 'Количество групп',
            prefixIcon: Icon(Icons.grid_view),
          ),
          items: [2, 4, 8].map((g) {
            return DropdownMenuItem(value: g, child: Text('$g группы'));
          }).toList(),
          onChanged: (v) => setState(() => _groupsCount = v),
        ),
        const SizedBox(height: 16),
        // Сколько проходит
        DropdownButtonFormField<int>(
          value: _advancingCount ?? 2,
          decoration: const InputDecoration(
            labelText: 'Проходят из группы',
            prefixIcon: Icon(Icons.arrow_forward),
          ),
          items: [1, 2, 3, 4].map((a) {
            return DropdownMenuItem(value: a, child: Text('$a ${_getAdvancingWord(a)}'));
          }).toList(),
          onChanged: (v) => setState(() => _advancingCount = v),
        ),
      ],
    );
  }

  String _getAdvancingWord(int count) {
    if (count == 1) return 'участник';
    if (count < 5) return 'участника';
    return 'участников';
  }

  Widget _buildDateTimeSelector() {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.calendar_today),
          title: Text(DateFormat('dd.MM.yyyy HH:mm').format(_startTime)),
          subtitle: const Text('Нажмите для изменения'),
          onTap: _pickDateTime,
        ),
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
      lastDate: DateTime.now().add(const Duration(days: 90)),
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
      {'code': 'standard', 'name': 'Стандартная'},
      {'code': 'kings_gambit', 'name': 'Королевский гамбит'},
      {'code': 'sicilian', 'name': 'Сицилианская'},
      {'code': 'custom', 'name': 'Своя позиция (FEN)'},
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
    final tournament = {
      'name': _nameController.text,
      'format': _format,
      'daysPerMove': _daysPerMove,
      'maxPlayers': _maxPlayers,
      'groupsCount': _format == 'groups' ? _groupsCount : null,
      'advancingCount': _format == 'groups' ? _advancingCount : null,
      'startTime': _startTime.toIso8601String(),
      'timeZone': _timeZone,
      'startingPosition': _startingPosition == 'custom'
          ? _customPositionController.text
          : _startingPosition,
    };

    _showSuccessDialog(tournament);
  }

  void _showSuccessDialog(Map<String, dynamic> tournament) {
    final code = 'DAY' + DateTime.now().millisecondsSinceEpoch.toString().substring(8, 13);

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
            Text(tournament['name'] as String),
            const SizedBox(height: 16),
            const Text('Код турнира:', style: TextStyle(color: Colors.grey)),
            SelectableText(
              code,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 4),
            ),
            const SizedBox(height: 8),
            Text(
              'Начало: ${DateFormat('dd.MM.yyyy').format(DateTime.parse(tournament['startTime']))}',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              '${tournament['daysPerMove']} дня на ход',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
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