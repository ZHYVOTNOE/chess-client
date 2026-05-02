import 'package:client/features/play/presentation/widgets/engine_config.dart';
import 'package:client/features/play/presentation/widgets/game_config.dart';
import 'package:client/features/play/presentation/widgets/player_color.dart';
import 'package:client/features/play/presentation/widgets/time_control.dart';
import 'package:flutter/material.dart';
import 'package:bishop/bishop.dart' as bishop;
import 'package:go_router/go_router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:squares/squares.dart';

import '../../../core/providers/game_provider.dart';
import '../../../core/providers/locale_provider.dart';

class SetupGameScreen extends StatefulWidget {
  const SetupGameScreen({
    super.key,
    this.initialMode,
  });

  final String? initialMode;

  @override
  State<SetupGameScreen> createState() => _SetupGameScreenState();
}

class _SetupGameScreenState extends State<SetupGameScreen> {
  final List<bishop.Variant> _variants = [
    bishop.Variant.standard(),
    bishop.Variant.chess960(),
    bishop.Variant.mini(),
    bishop.Variant.micro(),
    bishop.Variant.nano(),
    bishop.Variant.grand(),
    bishop.Variant.capablanca(),
    bishop.Variant.crazyhouse(),
    bishop.Variant.seirawan(),
    bishop.Xiangqi.variant(),
    bishop.Xiangqi.mini(),
    bishop.Variant.atomic(),
    bishop.Variant.kingOfTheHill(),
    bishop.Variant.horde(),
    bishop.MiscVariants.dart(),
    bishop.OtherGames.jesonMor(),
    bishop.CommonVariants.antichess(),
  ];

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

  final List<Map<String, dynamic>> _friends = [
    {'id': '1', 'name': 'Александр', 'rating': 1850, 'online': true},
    {'id': '2', 'name': 'Мария', 'rating': 1920, 'online': false},
    {'id': '3', 'name': 'Дмитрий', 'rating': 1780, 'online': true},
    {'id': '4', 'name': 'Елена', 'rating': 2100, 'online': true},
  ];

  final List<Map<String, dynamic>> _botLevels = [
    {'id': 'beginner', 'name': 'Новичок', 'rating': 400},
    {'id': 'intermediate', 'name': 'Любитель', 'rating': 800},
    {'id': 'advanced', 'name': 'Опытный', 'rating': 1400},
    {'id': 'expert', 'name': 'Эксперт', 'rating': 2000},
    {'id': 'master', 'name': 'Мастер', 'rating': 2500},
  ];

  final categories = [
    {'code': 'bullet', 'name': 'Bullet', 'icon': MdiIcons.bullet},
    {'code': 'blitz', 'name': 'Blitz', 'icon': Icons.bolt},
    {'code': 'rapid', 'name': 'Rapid', 'icon': Icons.timer},
    {'code': 'custom', 'name': 'Custom', 'icon': Icons.tune},
  ];

  List<DropdownMenuItem<int>> get _variantDropdownItems {
    List<DropdownMenuItem<int>> items = [];
    _variants.asMap().forEach(
          (k, v) => items.add(DropdownMenuItem(value: k, child: Text(v.name))),
    );
    return items;
  }

  int _variant = 0;
  String _selectedTime = '3|0';
  String _currentCategory = 'blitz';
  bool _showCustom = false;
  int _customMinutes = 5;
  int _customSeconds = 0;
  int _customIncrement = 0;
  String _ratingRange = '±200';
  String _selectedFriend = '';
  String _chosenColor = 'random';
  bool _rated = true;
  bool _botWithTime = false;
  String _selectedBot = 'intermediate';

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final mode = _resolveMode();
    final title = _modeTitle(locale, mode);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('Вариант шахмат'),
          _buildVariantDropdown(),
          const SizedBox(height: 16),
          if (mode == _SetupMode.random) ...[
            _buildSectionTitle('Контроль времени'),
            _buildTimeSelector(),
            const SizedBox(height: 16),
            _buildSectionTitle('Диапазон рейтинга'),
            _buildRatingRangeSelector(),
          ],
          if (mode == _SetupMode.friend) ...[
            _buildSectionTitle('Выбор друга'),
            _buildFriendSelector(),
            const SizedBox(height: 16),
            _buildSectionTitle('Контроль времени'),
            _buildTimeSelector(),
            const SizedBox(height: 16),
            _buildSectionTitle('Выбор цвета'),
            _buildColorSelector(),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Рейтинговая'),
              value: _rated,
              onChanged: (value) => setState(() => _rated = value),
            ),
          ],
          if (mode == _SetupMode.computer) ...[
            CheckboxListTile(
              title: const Text('Время'),
              value: _botWithTime,
              onChanged: (value) => setState(() => _botWithTime = value ?? false),
            ),
            if (_botWithTime) ...[
              const SizedBox(height: 8),
              _buildSectionTitle('Контроль времени'),
              _buildTimeSelector(),
              const SizedBox(height: 16),
            ],
            _buildSectionTitle('Выбор цвета'),
            _buildColorSelector(),
            const SizedBox(height: 16),
            _buildSectionTitle('Сложность'),
            _buildBotLevelSelector(),
          ],
          const SizedBox(height: 24),
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: () => _start(mode),
              child: Text(locale.get('start_game')),
            ),
          ),
        ],
      ),
    );
  }

  _SetupMode _resolveMode() {
    if (widget.initialMode != null) {
      return _modeFromString(widget.initialMode!);
    }
    final gameProvider = context.read<GameProvider>();
    if (gameProvider.vsRandom) return _SetupMode.random;
    if (gameProvider.vsFriend) return _SetupMode.friend;
    if (gameProvider.vsComputer) return _SetupMode.computer;
    return _SetupMode.random;
  }

  _SetupMode _modeFromString(String value) {
    switch (value) {
      case 'friend':
        return _SetupMode.friend;
      case 'computer':
        return _SetupMode.computer;
      case 'random':
      default:
        return _SetupMode.random;
    }
  }

  String _modeTitle(LocaleProvider locale, _SetupMode mode) {
    switch (mode) {
      case _SetupMode.friend:
        return locale.get('play_friend_title');
      case _SetupMode.computer:
        return locale.get('play_bot_title');
      case _SetupMode.random:
        return locale.get('quick_title');
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildVariantDropdown() {
    return DropdownButtonFormField<int>(
      value: _variant,
      items: _variantDropdownItems,
      onChanged: (value) => setState(() => _variant = value ?? _variant),
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildTimeSelector() {
    return Column(
      children: [
        _buildCategoryTabs(),
        const SizedBox(height: 12),
        _showCustom ? _buildCustomTime() : _buildTimeGrid(),
      ],
    );
  }

  Widget _buildCategoryTabs() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _currentCategory == category['code'];
          final isCustom = category['code'] == 'custom';
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              avatar: Icon(
                category['icon'] as IconData,
                size: 18,
                color: isSelected ? Colors.white : Colors.grey,
              ),
              label: Text(category['name'] as String),
              selected: isSelected,
              onSelected: (selected) {
                if (!selected) return;
                setState(() {
                  _currentCategory = category['code'] as String;
                  _showCustom = isCustom;
                  if (!isCustom) {
                    _selectedTime = _timeControls[_currentCategory]!.first['code'] as String;
                  }
                });
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
                    fontSize: 22,
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

  // Widget _buildCustomTime() {
  //   return Card(
  //     child: Padding(
  //       padding: const EdgeInsets.all(16),
  //       child: Column(
  //         children: [
  //           Row(
  //             children: [
  //               Expanded(
  //                 child: _buildNumberPicker(
  //                   label: 'Минуты',
  //                   value: _customMinutes,
  //                   max: 60,
  //                   onChanged: (value) => setState(() => _customMinutes = value),
  //                 ),
  //               ),
  //               const SizedBox(width: 16),
  //               Expanded(
  //                 child: _buildNumberPicker(
  //                   label: 'Секунды',
  //                   value: _customSeconds,
  //                   max: 59,
  //                   onChanged: (value) => setState(() => _customSeconds = value),
  //                 ),
  //               ),
  //               const SizedBox(width: 16),
  //               Expanded(
  //                 child: _buildNumberPicker(
  //                   label: 'Добавление',
  //                   value: _customIncrement,
  //                   max: 60,
  //                   onChanged: (value) => setState(() => _customIncrement = value),
  //                 ),
  //               ),
  //             ],
  //           ),
  //           const SizedBox(height: 16),
  //           Text(
  //             'Итого: $_customMinutes:${_customSeconds.toString().padLeft(2, '0')} + $_customIncrement',
  //             style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
  Widget _buildCustomTime() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 160,
              child: Row(
                children: [
                  // Минуты
                  Expanded(
                    child: _buildWheelPicker(
                      label: 'Мин',
                      value: _customMinutes,
                      max: 60,
                      onChanged: (value) => setState(() => _customMinutes = value),
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  // Секунды
                  Expanded(
                    child: _buildWheelPicker(
                      label: 'Сек',
                      value: _customSeconds,
                      max: 59,
                      onChanged: (value) => setState(() => _customSeconds = value),
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  // Добавление
                  Expanded(
                    child: _buildWheelPicker(
                      label: '+',
                      value: _customIncrement,
                      max: 60,
                      onChanged: (value) => setState(() => _customIncrement = value),
                    ),
                  ),
                ],
              ),
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

  Widget _buildWheelPicker({
    required String label,
    required int value,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        Expanded(
          child: ListWheelScrollView.useDelegate(
            itemExtent: 40,
            perspective: 0.005,
            diameterRatio: 1.2,
            physics: const FixedExtentScrollPhysics(),
            controller: FixedExtentScrollController(initialItem: value),
            onSelectedItemChanged: onChanged,
            childDelegate: ListWheelChildBuilderDelegate(
              builder: (context, index) {
                if (index < 0 || index > max) return null;
                final isSelected = index == value;
                return Center(
                  child: Text(
                    index.toString().padLeft(2, '0'),
                    style: TextStyle(
                      fontSize: isSelected ? 22 : 18,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.black : Colors.grey.shade400,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberPicker({
    required String label,
    required int value,
    required int max,
    required ValueChanged<int> onChanged,
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
    final ranges = ['±100', '±200', '±500', 'any'];
    return Column(
      children: ranges
          .map(
            (range) => RadioListTile<String>(
              value: range,
              groupValue: _ratingRange,
              onChanged: (value) => setState(() => _ratingRange = value ?? _ratingRange),
              title: Text(range == 'any' ? 'Любой' : range),
            ),
          )
          .toList(),
    );
  }

  Widget _buildFriendSelector() {
    return Column(
      children: _friends.map((friend) {
        final isSelected = _selectedFriend == friend['id'];
        return Card(
          color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
          child: ListTile(
            onTap: () => setState(() => _selectedFriend = friend['id'] as String),
            title: Text(friend['name'] as String),
            subtitle: Text('${friend['rating']}'),
            trailing: isSelected ? const Icon(Icons.check_circle) : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildColorSelector() {
    final selectedIndex = _colorIndex(_chosenColor);
    final pieceSet = PieceSet.merida();

    return Center(
      child: ToggleButtons(
        borderRadius: BorderRadius.circular(10),
        constraints: const BoxConstraints(minWidth: 54, minHeight: 44),
        isSelected: [
          selectedIndex == 0,
          selectedIndex == 1,
          selectedIndex == 2,
        ],
        onPressed: _changeColorByIndex,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: FittedBox(
              child: pieceSet.piece(context, 'K'),
            ),
          ),
          Icon(
            MdiIcons.helpCircleOutline,
            size: 30,
          ),
          SizedBox(
            width: 32,
            height: 32,
            child: FittedBox(
              child: pieceSet.piece(context, 'k'),
            ),
          ),
        ],
      ),
    );
  }

  int _colorIndex(String code) {
    switch (code) {
      case 'white':
        return 0;
      case 'black':
        return 2;
      case 'random':
      default:
        return 1;
    }
  }

  void _changeColorByIndex(int index) {
    final code = switch (index) {
      0 => 'white',
      2 => 'black',
      _ => 'random',
    };
    setState(() => _chosenColor = code);
  }

  Widget _buildBotLevelSelector() {
    return Column(
      children: _botLevels.map((bot) {
        return RadioListTile<String>(
          value: bot['id'] as String,
          groupValue: _selectedBot,
          onChanged: (value) => setState(() => _selectedBot = value ?? _selectedBot),
          title: Text(bot['name'] as String),
          subtitle: Text('Рейтинг: ${bot['rating']}'),
        );
      }).toList(),
    );
  }

  void _start(_SetupMode mode) {
    if (mode == _SetupMode.friend && _selectedFriend.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите друга')),
      );
      return;
    }

    final timeControl = (mode == _SetupMode.computer && !_botWithTime)
        ? const TimeControl.disabled()
        : (_showCustom
        ? TimeControl(
      minutes: _customMinutes,
      seconds: _customSeconds,
      increment: _customIncrement,
    )
        : TimeControl.parse(_selectedTime));

    final playerColor = _chosenColor == 'random'
        ? null
        : PlayerColor.fromCode(_chosenColor);

    final config = GameConfig.create(
      variant: _variants[_variant],
      humanPlayer: playerColor,
      opponentType: switch (mode) {
        _SetupMode.computer => OpponentType.ai,
        _SetupMode.friend => OpponentType.human,
        _SetupMode.random => OpponentType.ai,
      },
      engineConfig: mode == _SetupMode.computer
          ? EngineConfig.fromBotLevel(_selectedBot)
          : null,
      timeControl: timeControl,
      friendId: mode == _SetupMode.friend ? _selectedFriend : null,
      rated: mode == _SetupMode.friend ? _rated : true,
    );

    context.push('/game/play', extra: config);
  }
}

enum _SetupMode {
  random,
  friend,
  computer,
}
