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

  int _selectedBotLevel = 5; // Stockfish level 1-10

  String _chosenColor = 'random';

  bool _rated = false;



  List<Map<String, dynamic>> _botLevels(BuildContext context) {

    final locale = context.read<LocaleProvider>();

    return [

      {

        'level': 1,

        'name': locale.get('play_bot_level_1'),

        'rating': 400,

        'description': locale.get('play_bot_level_1_desc'),

        'color': Colors.green.shade300,

        'icon': Icons.sentiment_very_satisfied,

      },

      {

        'level': 2,

        'name': locale.get('play_bot_level_2'),

        'rating': 600,

        'description': locale.get('play_bot_level_2_desc'),

        'color': Colors.green.shade400,

        'icon': Icons.sentiment_satisfied,

      },

      {

        'level': 3,

        'name': locale.get('play_bot_level_3'),

        'rating': 800,

        'description': locale.get('play_bot_level_3_desc'),

        'color': Colors.green.shade600,

        'icon': Icons.sentiment_satisfied,

      },

      {

        'level': 4,

        'name': locale.get('play_bot_level_4'),

        'rating': 1000,

        'description': locale.get('play_bot_level_4_desc'),

        'color': Colors.blue.shade300,

        'icon': Icons.sentiment_neutral,

      },

      {

        'level': 5,

        'name': locale.get('play_bot_level_5'),

        'rating': 1200,

        'description': locale.get('play_bot_level_5_desc'),

        'color': Colors.blue.shade400,

        'icon': Icons.sentiment_neutral,

      },

      {

        'level': 6,

        'name': locale.get('play_bot_level_6'),

        'rating': 1400,

        'description': locale.get('play_bot_level_6_desc'),

        'color': Colors.blue.shade500,

        'icon': Icons.sentiment_neutral,

      },

      {

        'level': 7,

        'name': locale.get('play_bot_level_7'),

        'rating': 1600,

        'description': locale.get('play_bot_level_7_desc'),

        'color': Colors.orange.shade300,

        'icon': Icons.sentiment_dissatisfied,

      },

      {

        'level': 8,

        'name': locale.get('play_bot_level_8'),

        'rating': 1800,

        'description': locale.get('play_bot_level_8_desc'),

        'color': Colors.orange.shade400,

        'icon': Icons.sentiment_dissatisfied,

      },

      {

        'level': 9,

        'name': locale.get('play_bot_level_9'),

        'rating': 2000,

        'description': locale.get('play_bot_level_9_desc'),

        'color': Colors.purple.shade400,

        'icon': Icons.sentiment_very_dissatisfied,

      },

      {

        'level': 10,

        'name': locale.get('play_bot_level_10'),

        'rating': 2500,

        'description': locale.get('play_bot_level_10_desc'),

        'color': Colors.red.shade400,

        'icon': Icons.psychology,

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

      children: _botLevels(context).map((bot) {

        final isSelected = _selectedBotLevel == bot['level'];



        return Card(

          margin: EdgeInsets.only(bottom: 8.h),

          color: isSelected ? (bot['color'] as Color).withOpacity(0.1) : null,

          child: InkWell(

            onTap: () {

              setState(() => _selectedBotLevel = bot['level'] as int);

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

                            SizedBox(width: 8.w),

                            Container(

                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),

                              decoration: BoxDecoration(

                                color: Colors.grey.shade200,

                                borderRadius: BorderRadius.circular(4.r),

                              ),

                              child: Text(

                                'Lvl ${bot['level']}',

                                style: TextStyle(fontSize: 12.sp),

                              ),

                            ),

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

                        ),

                        SizedBox(height: 2.h),

                        Text(

                          bot['description'] as String,

                          style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),

                        ),

                      ],

                    ),

                  ),

                  if (isSelected)

                    Icon(Icons.check_circle, color: bot['color'] as Color),

                ],

              ),

            ),

          ),

        );

      }).toList(),

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

    final bot = _botLevels(context).firstWhere((b) => b['level'] == _selectedBotLevel);



    context.push('/game/play', extra: {

      'opponent': bot['name'],

      'opponentRating': bot['rating'],

      'botLevel': _selectedBotLevel, // Pass Stockfish level (1-10)

      'color': _chosenColor,

      'rated': _rated,

    });

  }

}