import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bishop/bishop.dart' as bishop;

import 'package:go_router/go_router.dart';

import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import 'package:provider/provider.dart';

import 'package:squares/squares.dart';

import 'package:supabase_flutter/supabase_flutter.dart';



import '../../../../core/providers/game_provider.dart';

import '../../../../core/providers/locale_provider.dart';

import '../../../../core/services/presence_service.dart';

import '../../../social/domain/entities/friend.dart';

import '../../../social/presentation/cubits/social_cubit.dart';

import '../../data/datasources/ratings_remote_datasource.dart';

import '../../data/repositories/game_setup_repository_impl.dart';

import '../../data/repositories/rating_repository_impl.dart';

import '../../domain/entities/engine_config.dart';

import '../../domain/entities/game_config.dart';

import '../../domain/entities/game_setup.dart';

import '../../domain/entities/player_color.dart';

import '../../domain/entities/time_control.dart';

import '../../domain/repositories/game_setup_repository.dart';

import '../../domain/repositories/rating_repository.dart';



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

  late final RatingRepository _ratingRepository;

  late final GameSetupRepository _gameSetupRepository;



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

    bishop.Variant.atomic(),

    bishop.Variant.kingOfTheHill(),

    bishop.Variant.horde(),

  ];



  final List<String> _variantKeys = [

    'standard',

    'chess960',

    'mini',

    'micro',

    'nano',

    'grand',

    'capablanca',

    'crazyhouse',

    'seirawan',

    'atomic',

    'kingOfTheHill',

    'horde',

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



  final List<Map<String, dynamic>> _botLevels = [

    {'level': 1, 'nameKey': 'play_bot_level_1', 'rating': 400},

    {'level': 2, 'nameKey': 'play_bot_level_2', 'rating': 600},

    {'level': 3, 'nameKey': 'play_bot_level_3', 'rating': 800},

    {'level': 4, 'nameKey': 'play_bot_level_4', 'rating': 1000},

    {'level': 5, 'nameKey': 'play_bot_level_5', 'rating': 1200},

    {'level': 6, 'nameKey': 'play_bot_level_6', 'rating': 1400},

    {'level': 7, 'nameKey': 'play_bot_level_7', 'rating': 1600},

    {'level': 8, 'nameKey': 'play_bot_level_8', 'rating': 1800},

    {'level': 9, 'nameKey': 'play_bot_level_9', 'rating': 2000},

    {'level': 10, 'nameKey': 'play_bot_level_10', 'rating': 2500},

  ];



  List<Map<String, dynamic>> _getCategories(LocaleProvider locale) => [

    {'code': 'bullet', 'name': locale.get('setup_category_bullet'), 'icon': MdiIcons.bullet},

    {'code': 'blitz', 'name': locale.get('setup_category_blitz'), 'icon': Icons.bolt},

    {'code': 'rapid', 'name': locale.get('setup_category_rapid'), 'icon': Icons.timer},

    {'code': 'custom', 'name': locale.get('setup_category_custom'), 'icon': Icons.tune},

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

  int _selectedBotLevel = 5; // Stockfish level 1-10



  @override

  void initState() {

    super.initState();

    _ratingRepository = RatingRepositoryImpl(

      RatingsRemoteDataSource(Supabase.instance.client),

    );

    _gameSetupRepository = GameSetupRepositoryImpl(

      Supabase.instance.client,

    );

    _loadSavedSettings();

  }



  Future<void> _loadSavedSettings() async {

    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId == null) return;



    try {

      final savedSetup = await _gameSetupRepository.getGameSetup(userId);

      if (savedSetup != null) {

        setState(() {

          final variantIndex = _variantKeys.indexOf(savedSetup.variant);

          if (variantIndex >= 0) _variant = variantIndex;

          _currentCategory = savedSetup.timeControlCategory;

          _selectedTime = savedSetup.timeControl;

          _ratingRange = savedSetup.ratingRange;

        });

      }

    } catch (e) {

      // Ignore errors, use defaults

    }

  }



  Future<void> _saveSettings() async {

    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId == null) return;



    try {

      final setup = GameSetup(

        userId: userId,

        variant: _variantKeys[_variant],

        timeControl: _selectedTime,

        timeControlCategory: _currentCategory,

        ratingRange: _ratingRange,

      );

      await _gameSetupRepository.saveGameSetup(setup);

    } catch (e) {

      // Ignore save errors

    }

  }



  /// Сортировка друзей: онлайн первыми, потом по последнему входу

  List<Friend> _sortFriends(List<Friend> friends) {

    final sorted = [...friends]

      ..sort((a, b) {

        final aOnline = PresenceService.isOnline(a.lastSeenAt);

        final bOnline = PresenceService.isOnline(b.lastSeenAt);



        // Онлайн всегда первыми

        if (aOnline && !bOnline) return -1;

        if (!aOnline && bOnline) return 1;



        // Оба онлайн или оба офлайн — сортируем по lastSeenAt (недавние первыми)

        if (a.lastSeenAt == null && b.lastSeenAt == null) return 0;

        if (a.lastSeenAt == null) return 1;

        if (b.lastSeenAt == null) return -1;

        return b.lastSeenAt!.compareTo(a.lastSeenAt!);

      });

    return sorted;

  }



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

          _buildSectionTitle(locale.get('setup_chess_variant')),

          _buildVariantDropdown(),

          const SizedBox(height: 16),



          if (mode == _SetupMode.random) ...[

            _buildSectionTitle(locale.get('time_control')),

            _buildTimeSelector(locale),

            const SizedBox(height: 16),

            _buildSectionTitle(locale.get('quick_rating_range')),

            _buildRatingRangeSelector(locale),

          ],



          if (mode == _SetupMode.friend) ...[

            _buildSectionTitle(locale.get('setup_friend_selection')),

            _buildFriendSelector(locale),

            const SizedBox(height: 16),

            _buildSectionTitle(locale.get('time_control')),

            _buildTimeSelector(locale),

            const SizedBox(height: 16),

            _buildSectionTitle(locale.get('choose_color')),

            _buildColorSelector(),

            const SizedBox(height: 16),

            SwitchListTile(

              title: Text(locale.get('setup_rated')),

              value: _rated,

              onChanged: (value) => setState(() => _rated = value),

            ),

          ],



          if (mode == _SetupMode.computer) ...[

            CheckboxListTile(

              title: Text(locale.get('setup_time')),

              value: _botWithTime,

              onChanged: (value) => setState(() => _botWithTime = value ?? false),

            ),

            if (_botWithTime) ...[

              const SizedBox(height: 8),

              _buildSectionTitle(locale.get('time_control')),

              _buildTimeSelector(locale),

              const SizedBox(height: 16),

            ],

            _buildSectionTitle(locale.get('choose_color')),

            _buildColorSelector(),

            const SizedBox(height: 16),

            _buildSectionTitle(locale.get('setup_difficulty')),

            _buildBotLevelSelector(locale),

          ],



          const SizedBox(height: 24),

          SizedBox(

            height: 54,

            child: ElevatedButton(

              onPressed: () async => await _start(mode, locale),

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

      initialValue: _variant,

      items: _variantDropdownItems,

      onChanged: (value) {

        setState(() => _variant = value ?? _variant);

        _saveSettings();

      },

      decoration: const InputDecoration(

        border: OutlineInputBorder(),

      ),

    );

  }



  Widget _buildTimeSelector(LocaleProvider locale) {

    return Column(

      children: [

        _buildCategoryTabs(locale),

        const SizedBox(height: 12),

        _showCustom ? _buildCustomTime(locale) : _buildTimeGrid(),

      ],

    );

  }



  Widget _buildCategoryTabs(LocaleProvider locale) {

    final categories = _getCategories(locale);

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

                _saveSettings();

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

          onTap: () {

            setState(() => _selectedTime = time['code'] as String);

            _saveSettings();

          },

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



  Widget _buildCustomTime(LocaleProvider locale) {

    return Card(

      child: Padding(

        padding: const EdgeInsets.all(16),

        child: Column(

          children: [

            SizedBox(

              height: 160,

              child: Row(

                children: [

                  Expanded(

                    child: _buildWheelPicker(

                      label: locale.get('setup_minutes_short'),

                      value: _customMinutes,

                      max: 60,

                      onChanged: (value) => setState(() => _customMinutes = value),

                    ),

                  ),

                  const VerticalDivider(width: 1),

                  Expanded(

                    child: _buildWheelPicker(

                      label: locale.get('setup_seconds_short'),

                      value: _customSeconds,

                      max: 59,

                      onChanged: (value) => setState(() => _customSeconds = value),

                    ),

                  ),

                  const VerticalDivider(width: 1),

                  Expanded(

                    child: _buildWheelPicker(

                      label: locale.get('setup_increment_short'),

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

              '${locale.get('quick_custom_total')} $_customMinutes:${_customSeconds.toString().padLeft(2, '0')} + $_customIncrement',

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



  Widget _buildRatingRangeSelector(LocaleProvider locale) {

    final ranges = ['±50', '±100', '±200', 'any'];

    return Column(

      children: ranges

          .map(

            (range) => RadioListTile<String>(

          value: range,

          groupValue: _ratingRange,

          onChanged: (value) {

            setState(() => _ratingRange = value ?? _ratingRange);

            _saveSettings();

          },

          title: Text(range == 'any' ? locale.get('quick_rating_any') : range),

        ),

      )

          .toList(),

    );

  }



  Widget _buildFriendSelector(LocaleProvider locale) {

    return BlocBuilder<SocialCubit, SocialState>(

      builder: (context, socialState) {

        final friends = socialState.friends;



        if (friends.isEmpty) {

          return Card(

            child: Padding(

              padding: const EdgeInsets.all(24),

              child: Column(

                children: [

                  const Icon(Icons.people_outline, size: 48, color: Colors.grey),

                  const SizedBox(height: 16),

                  Text(

                    locale.get('play_friend_add_friends'),

                    style: const TextStyle(color: Colors.grey),

                    textAlign: TextAlign.center,

                  ),

                  const SizedBox(height: 16),

                  OutlinedButton(

                    onPressed: () => context.push('/more/friends'),

                    child: Text(locale.get('play_friend_find_friends')),

                  ),

                ],

              ),

            ),

          );

        }



        // Сортируем друзей

        final sorted = _sortFriends(friends);



        return Column(

          children: sorted.map((friend) {

            final isSelected = _selectedFriend == friend.friendId;

            final isOnline = PresenceService.isOnline(friend.lastSeenAt);

            final statusText = PresenceService.formatLastSeen(friend.lastSeenAt);



            return Card(

              margin: const EdgeInsets.only(bottom: 8),

              color: isSelected

                  ? Theme.of(context).primaryColor.withOpacity(0.1)

                  : null,

              child: ListTile(

                onTap: () => setState(() => _selectedFriend = friend.friendId),

                leading: Stack(

                  children: [

                    CircleAvatar(

                      backgroundColor: Colors.grey.shade300,

                      backgroundImage: friend.friendAvatarUrl != null && friend.friendAvatarUrl!.isNotEmpty

                          ? NetworkImage(friend.friendAvatarUrl!)

                          : null,

                      child: friend.friendAvatarUrl == null || friend.friendAvatarUrl!.isEmpty

                          ? Text(

                        friend.friendNickname.isNotEmpty

                            ? friend.friendNickname[0].toUpperCase()

                            : '?',

                      )

                          : null,

                    ),

                    Positioned(

                      bottom: 0,

                      right: 0,

                      child: Container(

                        width: 12,

                        height: 12,

                        decoration: BoxDecoration(

                          color: isOnline ? Colors.green : Colors.grey,

                          shape: BoxShape.circle,

                          border: Border.all(color: Colors.white, width: 2),

                        ),

                      ),

                    ),

                  ],

                ),

                title: Text(

                  friend.friendNickname,

                  style: const TextStyle(fontWeight: FontWeight.w500),

                ),

                subtitle: Text(

                  isOnline

                      ? locale.get('play_friend_online')

                      : statusText,

                  style: TextStyle(

                    color: isOnline ? Colors.green : Colors.grey.shade600,

                    fontSize: 12,

                  ),

                ),

                trailing: isSelected

                    ? const Icon(Icons.check_circle, color: Colors.green)

                    : null,

              ),

            );

          }).toList(),

        );

      },

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



  Widget _buildBotLevelSelector(LocaleProvider locale) {

    return Column(

      children: _botLevels.map((bot) {

        return RadioListTile<int>(

          value: bot['level'] as int,

          groupValue: _selectedBotLevel,

          onChanged: (value) => setState(() => _selectedBotLevel = value ?? _selectedBotLevel),

          title: Text(locale.get(bot['nameKey'] as String)),

          subtitle: Text('${locale.get('setup_bot_rating')}: ${bot['rating']}'),

        );

      }).toList(),

    );

  }



  Future<void> _start(_SetupMode mode, LocaleProvider locale) async {

    if (mode == _SetupMode.friend && _selectedFriend.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(content: Text(locale.get('setup_select_friend_required'))),

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



    if (mode == _SetupMode.random) {

      final jwtToken = Supabase.instance.client.auth.currentSession?.accessToken;

      if (jwtToken == null) {

        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(content: Text(locale.get('setup_not_authorized'))),

        );

        return;

      }



      final timeControlType = _currentCategory;

      final userId = Supabase.instance.client.auth.currentUser?.id;

      int userRating = 1500;



      if (userId != null) {

        try {

          final rating = await _ratingRepository.getRating(

            userId,

            _variants[_variant].name,

            timeControlType,

          );

          if (rating != null) {

            userRating = rating.rating.toInt();

          }

        } catch (e) {

          userRating = 1500;

        }

      }



      print('🎮 [MATCHMAKING] Starting search with params:');

      print('   variant: ${_variantKeys[_variant]}');

      print('   timeControlType: $timeControlType');

      print('   timeControl: $_selectedTime');

      print('   rating: $userRating');

      print('   ratingRange: $_ratingRange');

      print('   userId: $userId');

      print('   hasToken: ${jwtToken != null}');



      context.push('/game/searching', extra: {

        'jwtToken': jwtToken,

        'userId': userId,

        'variant': _variantKeys[_variant],

        'timeControlType': timeControlType,

        'timeControl': _selectedTime,

        'rating': userRating,

        'ratingRange': _ratingRange,

      });

      return;

    }



    // Get opponent data for friend games
    String? opponentName;
    int? opponentRating;
    String? opponentAvatarUrl;

    if (mode == _SetupMode.friend) {
      final socialCubit = context.read<SocialCubit>();
      final socialState = socialCubit.state;
      final friend = socialState.friends.firstWhere((f) => f.friendId == _selectedFriend);
      opponentName = friend.friendNickname;
      opponentAvatarUrl = friend.friendAvatarUrl;

      // Get friend's rating for the current game mode
      final gameMode = timeControl.gameMode;
      // Map variant name to database format
      final variantName = _variants[_variant].name == 'Chess' ? 'standard' : _variants[_variant].name;
      try {
        final rating = await _ratingRepository.getRating(
          _selectedFriend,
          variantName,
          gameMode,
        );
        opponentRating = rating?.rating.toInt();
      } catch (e) {
        opponentRating = null;
      }
    }

    final config = GameConfig.create(

      variant: _variants[_variant],

      humanPlayer: playerColor,

      opponentType: switch (mode) {

        _SetupMode.computer => OpponentType.ai,

        _SetupMode.friend => OpponentType.human,

        _SetupMode.random => OpponentType.ai,

      },

      engineConfig: mode == _SetupMode.computer

          ? EngineConfig.fromBotLevel(_selectedBotLevel)

          : null,

      timeControl: timeControl,

      friendId: mode == _SetupMode.friend ? _selectedFriend : null,

      rated: mode == _SetupMode.friend ? _rated : true,
      opponentName: opponentName,
      opponentRating: opponentRating,
      opponentAvatarUrl: opponentAvatarUrl,

    );



    context.push('/game/play', extra: config);

  }

}



enum _SetupMode {

  random,

  friend,

  computer,

}