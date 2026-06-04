import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../social/data/repositories/friend_repository_impl.dart';
import '../../../social/data/services/friend_service.dart';
import '../../../social/domain/entities/friend.dart';
import '../../../social/domain/repositories/friend_repository.dart';

class PlayFriendScreen extends StatefulWidget {
  final Friend? preselectedFriend;
  const PlayFriendScreen({super.key, this.preselectedFriend});

  @override
  State<PlayFriendScreen> createState() => _PlayFriendScreenState();
}

class _PlayFriendScreenState extends State<PlayFriendScreen> {
  String _selectedTime = '10|0';
  String _selectedFriend = '';
  bool _rated = true;
  String _chosenColor = 'random';
  bool _showAllFriends = false;

  late final FriendRepository _friendRepository;
  late final FriendService _friendService;
  List<Map<String, dynamic>> _friends = [];
  bool _isLoadingFriends = true;

  final List<Map<String, dynamic>> _timeControls = [
    {'code': '1|0', 'name': 'Bullet', 'minutes': 1, 'increment': 0},
    {'code': '3|0', 'name': 'Blitz', 'minutes': 3, 'increment': 0},
    {'code': '3|2', 'name': 'Blitz+', 'minutes': 3, 'increment': 2},
    {'code': '5|0', 'name': '5 мин', 'minutes': 5, 'increment': 0},
    {'code': '10|0', 'name': 'Rapid', 'minutes': 10, 'increment': 0},
    {'code': '15|10', 'name': 'Rapid+', 'minutes': 15, 'increment': 10},
    {'code': '30|0', 'name': 'Classical', 'minutes': 30, 'increment': 0},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.preselectedFriend != null) {
      _selectedFriend = widget.preselectedFriend!.friendId;
    }
    _friendRepository = FriendRepositoryImpl(Supabase.instance.client);
    _friendService = FriendService(_friendRepository, Supabase.instance.client);
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('PlayFriend: userId is null');
        return;
      }

      debugPrint('PlayFriend: loading friends for $userId');
      final friends = await _friendRepository.getFriends(userId);
      debugPrint('PlayFriend: got ${friends.length} friends');

      setState(() {
        _friends = friends.map((friend) => {
          'id': friend.friendId,
          'name': friend.friendNickname,
          'online': friend.isOnline,
        }).toList();
        _isLoadingFriends = false;
      });

      debugPrint('PlayFriend: _friends = $_friends');
    } catch (e) {
      debugPrint('PlayFriend ERROR: $e');
      setState(() => _isLoadingFriends = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load friends: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(locale.get('play_friend_title')),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Выбор друга
            _buildSectionTitle(locale.get('select_friend')),
            _buildFriendSelector(),
            const SizedBox(height: 24),

            // Временной контроль
            _buildSectionTitle(locale.get('time_control')),
            _buildTimeSelector(),
            const SizedBox(height: 24),

            // Выбор цвета
            _buildSectionTitle(locale.get('choose_color')),
            _buildColorSelector(),
            const SizedBox(height: 24),

            // Рейтинговая игра
            _buildRatedOption(),
            const SizedBox(height: 32),

            // Кнопка приглашения
            _buildInviteButton(locale),
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

  Widget _buildFriendSelector() {
    if (_isLoadingFriends) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_friends.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.people_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Добавьте друзей для игры',
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => context.push('/more/friends'),
                child: const Text('Найти друзей'),
              ),
            ],
          ),
        ),
      );
    }

    // Сортируем: онлайн первыми
    final sorted = [..._friends]
      ..sort((a, b) => (b['online'] as bool) ? 1 : -1);

    final showAll = _showAllFriends; // bool в стейте
    final displayed = showAll ? sorted : sorted.take(3).toList();

    return Column(
      children: [
        ...displayed.map((friend) {
          final isSelected = _selectedFriend == friend['id'];
          final isOnline = friend['online'] as bool;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: isSelected
                ? Theme.of(context).primaryColor.withOpacity(0.1)
                : null,
            child: ListTile(
              onTap: () => setState(() => _selectedFriend = friend['id'] as String),
              leading: Stack(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.grey.shade300,
                    child: Text((friend['name'] as String)[0]),
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      width: 12, height: 12,
                      decoration: BoxDecoration(
                        color: isOnline ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              title: Text(friend['name'] as String),
              subtitle: Text(isOnline ? 'онлайн' : 'офлайн'),
              trailing: isSelected
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
            ),
          );
        }),
        if (sorted.length > 3)
          TextButton(
            onPressed: () => setState(() => _showAllFriends = !_showAllFriends),
            child: Text(showAll ? 'Скрыть' : 'Все друзья (${sorted.length})'),
          ),
      ],
    );
  }

  Widget _buildTimeSelector() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _timeControls.length,
        itemBuilder: (context, index) {
          final time = _timeControls[index];
          final isSelected = _selectedTime == time['code'];

          return GestureDetector(
            onTap: () => setState(() => _selectedTime = time['code'] as String),
            child: Container(
              width: 80,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${time['minutes']}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    '+${time['increment']}',
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected ? Colors.white70 : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time['name'] as String,
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
                    'Результат повлияет на рейтинг',
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

  Widget _buildInviteButton(LocaleProvider locale) {
    final canInvite = _selectedFriend.isNotEmpty;

    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: canInvite ? _sendInvite : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canInvite ? null : Colors.grey,
        ),
        child: Text(
          locale.get('send_invite'),
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }

  void _sendInvite() async {
    final friend = _friends.firstWhere((f) => f['id'] == _selectedFriend);

    try {
      // Parse time control
      final timeParts = _selectedTime.split('|');
      final minutes = int.parse(timeParts[0]);
      final increment = int.parse(timeParts[1]);

      final gameConfig = {
        'variant': 'standard',
        'timeControl': {
          'initial': Duration(minutes: minutes).inSeconds,
          'increment': Duration(seconds: increment).inSeconds,
        },
        'rated': _rated,
        'color': _chosenColor,
      };

      await _friendService.sendGameInvite(_selectedFriend, gameConfig);

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Приглашение отправлено'),
            content: Text('Ожидаем ответа от ${friend['name']}...'),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ОК'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send invite: $e')),
        );
      }
    }
  }
}