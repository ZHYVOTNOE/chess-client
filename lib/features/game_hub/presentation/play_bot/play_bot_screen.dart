import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/locale_provider.dart';

class PlayBotScreen extends StatefulWidget {
  const PlayBotScreen({super.key});

  @override
  State<PlayBotScreen> createState() => _PlayBotScreenState();
}

class _PlayBotScreenState extends State<PlayBotScreen> {
  String _selectedBot = 'intermediate';
  String _chosenColor = 'random';
  bool _rated = false;

  final List<Map<String, dynamic>> _bots = [
    {
      'id': 'beginner',
      'name': 'Новичок',
      'rating': 400,
      'description': 'Только начинает изучать шахматы',
      'color': Colors.green,
      'icon': Icons.sentiment_satisfied,
    },
    {
      'id': 'intermediate',
      'name': 'Любитель',
      'rating': 800,
      'description': 'Знает основные правила и простые тактики',
      'color': Colors.blue,
      'icon': Icons.sentiment_neutral,
    },
    {
      'id': 'advanced',
      'name': 'Опытный',
      'rating': 1400,
      'description': 'Играет уверенно, знает дебюты',
      'color': Colors.orange,
      'icon': Icons.sentiment_dissatisfied,
    },
    {
      'id': 'expert',
      'name': 'Эксперт',
      'rating': 2000,
      'description': 'Сильный игрок, сложные комбинации',
      'color': Colors.purple,
      'icon': Icons.sentiment_very_dissatisfied,
    },
    {
      'id': 'master',
      'name': 'Мастер',
      'rating': 2500,
      'description': 'Почти непобедим, глубокий расчёт',
      'color': Colors.red,
      'icon': Icons.psychology,
    },
    {
      'id': 'custom',
      'name': 'Настроить',
      'rating': null,
      'description': 'Выбери силу и стиль игры бота',
      'color': Colors.grey,
      'icon': Icons.tune,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(locale.get('play_bot_title')),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Выбор бота
            _buildSectionTitle(locale.get('select_bot')),
            _buildBotSelector(),
            const SizedBox(height: 24),

            // Выбор цвета
            _buildSectionTitle(locale.get('choose_color')),
            _buildColorSelector(),
            const SizedBox(height: 24),

            // Рейтинговая игра
            _buildRatedOption(),
            const SizedBox(height: 32),

            // Кнопка начала игры
            _buildStartButton(locale),
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

  Widget _buildBotSelector() {
    return Column(
      children: _bots.map((bot) {
        final isSelected = _selectedBot == bot['id'];
        final isCustom = bot['id'] == 'custom';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: isSelected ? (bot['color'] as Color).withOpacity(0.1) : null,
          child: InkWell(
            onTap: () {
              setState(() => _selectedBot = bot['id'] as String);
              if (isCustom) {
                _showCustomBotDialog();
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: (bot['color'] as Color).withOpacity(0.2),
                    child: Icon(
                      bot['icon'] as IconData,
                      color: bot['color'] as Color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              bot['name'] as String,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (bot['rating'] != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${bot['rating']}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          bot['description'] as String,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected && !isCustom)
                    Icon(Icons.check_circle, color: bot['color'] as Color),
                  if (isCustom && isSelected)
                    const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showCustomBotDialog() {
    // TODO: диалог настройки силы и стиля бота
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Настройка бота'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Сила бота (ELO)
            const Text('Сила бота'),
            Slider(
              value: 1500,
              min: 400,
              max: 2800,
              divisions: 24,
              label: '1500',
              onChanged: (v) {},
            ),
            // Стиль игры
            const Text('Стиль игры'),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(label: const Text('Универсальный'), selected: true, onSelected: (_) {}),
                ChoiceChip(label: const Text('Атакующий'), selected: false, onSelected: (_) {}),
                ChoiceChip(label: const Text('Позиционный'), selected: false, onSelected: (_) {}),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Применить'),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSelector() {
    final colors = [
      {'code': 'white', 'name': 'Белые', 'icon': Icons.circle_outlined},
      {'code': 'random', 'name': 'Случайно', 'icon': Icons.shuffle},
      {'code': 'black', 'name': 'Чёрные', 'icon': Icons.circle},
    ];

    return Row(
      children: colors.map((color) {
        final isSelected = _chosenColor == color['code'];
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _chosenColor = color['code'] as String),
            child: Card(
              color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      color['icon'] as IconData,
                      color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      color['name'] as String,
                      style: TextStyle(
                        color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRatedOption() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Рейтинговая игра',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'Победа/поражение влияет на рейтинг бота',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Switch(
              value: _rated,
              onChanged: (v) => setState(() => _rated = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton(LocaleProvider locale) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _startGame,
        child: Text(
          locale.get('start_game'),
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }

  void _startGame() {
    final bot = _bots.firstWhere((b) => b['id'] == _selectedBot);

    // TODO: API создания игры с ботом

    context.push('/game/play', extra: {
      'opponent': bot['name'],
      'opponentRating': bot['rating'],
      'color': _chosenColor,
      'rated': _rated,
    });
  }
}