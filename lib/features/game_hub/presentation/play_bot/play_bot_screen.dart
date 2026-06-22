import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:client/core/providers/locale_provider.dart';

class PlayBotScreen extends StatefulWidget {
  const PlayBotScreen({super.key});

  @override
  State<PlayBotScreen> createState() => _PlayBotScreenState();
}

class _PlayBotScreenState extends State<PlayBotScreen> {
  String _selectedBot = 'intermediate';
  String _chosenColor = 'random';
  bool _rated = false;

  List<Map<String, dynamic>> _bots(BuildContext context) {
    final locale = context.read<LocaleProvider>();
    return [
      {
        'id': 'beginner',
        'nameKey': 'play_bot_beginner',
        'name': locale.get('play_bot_beginner'),
        'rating': 400,
        'descriptionKey': 'play_bot_beginner_desc',
        'description': locale.get('play_bot_beginner_desc'),
        'color': Colors.green,
        'icon': Icons.sentiment_satisfied,
      },
      {
        'id': 'intermediate',
        'nameKey': 'play_bot_intermediate',
        'name': locale.get('play_bot_intermediate'),
        'rating': 800,
        'descriptionKey': 'play_bot_intermediate_desc',
        'description': locale.get('play_bot_intermediate_desc'),
        'color': Colors.blue,
        'icon': Icons.sentiment_neutral,
      },
      {
        'id': 'advanced',
        'nameKey': 'play_bot_advanced',
        'name': locale.get('play_bot_advanced'),
        'rating': 1400,
        'descriptionKey': 'play_bot_advanced_desc',
        'description': locale.get('play_bot_advanced_desc'),
        'color': Colors.orange,
        'icon': Icons.sentiment_dissatisfied,
      },
      {
        'id': 'expert',
        'nameKey': 'play_bot_expert',
        'name': locale.get('play_bot_expert'),
        'rating': 2000,
        'descriptionKey': 'play_bot_expert_desc',
        'description': locale.get('play_bot_expert_desc'),
        'color': Colors.purple,
        'icon': Icons.sentiment_very_dissatisfied,
      },
      {
        'id': 'master',
        'nameKey': 'play_bot_master',
        'name': locale.get('play_bot_master'),
        'rating': 2500,
        'descriptionKey': 'play_bot_master_desc',
        'description': locale.get('play_bot_master_desc'),
        'color': Colors.red,
        'icon': Icons.psychology,
      },
      {
        'id': 'custom',
        'nameKey': 'play_bot_custom',
        'name': locale.get('play_bot_custom'),
        'rating': null,
        'descriptionKey': 'play_bot_custom_desc',
        'description': locale.get('play_bot_custom_desc'),
        'color': Colors.grey,
        'icon': Icons.tune,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(locale.get('play_bot_title')),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Выбор бота
            _buildSectionTitle(locale.get('select_bot')),
            _buildBotSelector(),
            SizedBox(height: 24.h),

            // Выбор цвета
            _buildSectionTitle(locale.get('choose_color')),
            _buildColorSelector(),
            SizedBox(height: 24.h),

            // Рейтинговая игра
            _buildRatedOption(),
            SizedBox(height: 32.h),

            // Кнопка начала игры
            _buildStartButton(locale),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Text(
        title,
        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }

  Widget _buildBotSelector() {
    return Column(
      children: _bots(context).map((bot) {
        final isSelected = _selectedBot == bot['id'];
        final isCustom = bot['id'] == 'custom';

        return Card(
          margin: EdgeInsets.only(bottom: 8.h),
          color: isSelected ? (bot['color'] as Color).withOpacity(0.1) : null,
          child: InkWell(
            onTap: () {
              setState(() => _selectedBot = bot['id'] as String);
              if (isCustom) {
                _showCustomBotDialog();
              }
            },
            child: Padding(
              padding: EdgeInsets.all(12.r),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: (bot['color'] as Color).withOpacity(0.2),
                    child: Icon(
                      bot['icon'] as IconData,
                      color: bot['color'] as Color,
                    ),
                  ),
                  SizedBox(width: 12.w),
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
                              SizedBox(width: 8.w),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                                child: Text(
                                  '${bot['rating']}',
                                  style: TextStyle(fontSize: 12.sp),
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          bot['description'] as String,
                          style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected && !isCustom)
                    Icon(Icons.check_circle, color: bot['color'] as Color),
                  if (isCustom && isSelected)
                    Icon(Icons.arrow_forward_ios, size: 16.r),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showCustomBotDialog() {
    final locale = context.read<LocaleProvider>();
    // TODO: диалог настройки силы и стиля бота
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(locale.get('play_bot_settings_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Сила бота (ELO)
            Text(locale.get('play_bot_strength_label')),
            Slider(
              value: 1500,
              min: 400,
              max: 2800,
              divisions: 24,
              label: '1500',
              onChanged: (v) {},
            ),
            // Стиль игры
            Text(locale.get('play_bot_style_label')),
            Wrap(
              spacing: 8.w,
              children: [
                ChoiceChip(label: Text(locale.get('play_bot_style_universal')), selected: true, onSelected: (_) {}),
                ChoiceChip(label: Text(locale.get('play_bot_style_attacking')), selected: false, onSelected: (_) {}),
                ChoiceChip(label: Text(locale.get('play_bot_style_positional')), selected: false, onSelected: (_) {}),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(locale.get('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(locale.get('apply')),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSelector() {
    final locale = context.read<LocaleProvider>();
    final colors = [
      {'code': 'white', 'name': locale.get('play_bot_white'), 'icon': Icons.circle_outlined},
      {'code': 'random', 'name': locale.get('play_bot_random'), 'icon': Icons.shuffle},
      {'code': 'black', 'name': locale.get('play_bot_black'), 'icon': Icons.circle},
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
                padding: EdgeInsets.all(16.r),
                child: Column(
                  children: [
                    Icon(
                      color['icon'] as IconData,
                      color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                      size: 32.r,
                    ),
                    SizedBox(height: 8.h),
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
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
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
      height: 56.h,
      child: ElevatedButton(
        onPressed: _startGame,
        child: Text(
          locale.get('start_game'),
          style: TextStyle(fontSize: 18.sp),
        ),
      ),
    );
  }

  void _startGame() {
    final bot = _bots(context).firstWhere((b) => b['id'] == _selectedBot);

    // TODO: API создания игры с ботом

    context.push('/game/play', extra: {
      'opponent': bot['name'],
      'opponentRating': bot['rating'],
      'color': _chosenColor,
      'rated': _rated,
    });
  }
}