import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/locale_provider.dart';
import '../../../../core/services/presence_service.dart';
import '../../../social/domain/entities/friend.dart';
import '../../../social/presentation/cubits/social_cubit.dart';

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
  bool _isSendingInvite = false;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedFriend != null) {
      _selectedFriend = widget.preselectedFriend!.friendId;
    }
  }

  /// Генерируем список тайм-контролов динамически с учётом локали
  List<Map<String, dynamic>> _buildTimeControls(LocaleProvider locale) => [
    {'code': '1|0', 'name': locale.get('setup_category_bullet'), 'minutes': 1, 'increment': 0},
    {'code': '3|0', 'name': locale.get('setup_category_blitz'), 'minutes': 3, 'increment': 0},
    {'code': '3|2', 'name': '${locale.get('setup_category_blitz')}+', 'minutes': 3, 'increment': 2},
    {'code': '5|0', 'name': locale.get('setup_category_5_min'), 'minutes': 5, 'increment': 0},
    {'code': '10|0', 'name': locale.get('setup_category_rapid'), 'minutes': 10, 'increment': 0},
    {'code': '15|10', 'name': '${locale.get('setup_category_rapid')}+', 'minutes': 15, 'increment': 10},
    {'code': '30|0', 'name': locale.get('setup_category_classical'), 'minutes': 30, 'increment': 0},
  ];

  /// Сортировка друзей: сначала онлайн, потом по последнему входу (новые первыми)
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

    return Scaffold(
      appBar: AppBar(
        title: Text(locale.get('play_friend_title')),
        centerTitle: true,
      ),
      body: BlocBuilder<SocialCubit, SocialState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionTitle(locale.get('select_friend')),
                _buildFriendSelector(state.friends, locale),
                const SizedBox(height: 24),

                _buildSectionTitle(locale.get('time_control')),
                _buildTimeSelector(locale),
                const SizedBox(height: 24),

                _buildSectionTitle(locale.get('choose_color')),
                _buildColorSelector(locale),
                const SizedBox(height: 24),

                _buildRatedOption(locale),
                const SizedBox(height: 32),

                _buildInviteButton(locale),
              ],
            ),
          );
        },
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

  Widget _buildFriendSelector(List<Friend> friends, LocaleProvider locale) {
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
    final showAll = _showAllFriends;
    final displayed = showAll ? sorted : sorted.take(3).toList();

    return Column(
      children: [
        ...displayed.map((friend) {
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
        }),
        if (sorted.length > 3)
          TextButton(
            onPressed: () => setState(() => _showAllFriends = !_showAllFriends),
            child: Text(
              showAll
                  ? locale.get('play_friend_hide')
                  : '${locale.get('play_friend_all_friends')}${sorted.length})',
            ),
          ),
      ],
    );
  }

  Widget _buildTimeSelector(LocaleProvider locale) {
    final timeControls = _buildTimeControls(locale);

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: timeControls.length,
        itemBuilder: (context, index) {
          final time = timeControls[index];
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

  Widget _buildColorSelector(LocaleProvider locale) {
    final colors = [
      {
        'code': 'white',
        'name': locale.get('play_friend_white'),
        'icon': Icons.circle_outlined,
      },
      {
        'code': 'random',
        'name': locale.get('play_friend_random'),
        'icon': Icons.shuffle,
      },
      {
        'code': 'black',
        'name': locale.get('play_friend_black'),
        'icon': Icons.circle,
      },
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

  Widget _buildRatedOption(LocaleProvider locale) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    locale.get('play_friend_rated_game'),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    locale.get('play_friend_rated_desc'),
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
    final canInvite = _selectedFriend.isNotEmpty && !_isSendingInvite;

    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: canInvite ? () => _sendInvite(locale) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canInvite ? null : Colors.grey,
        ),
        child: _isSendingInvite
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : Text(
          locale.get('send_invite'),
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }

  void _sendInvite(LocaleProvider locale) async {
    if (_isSendingInvite) return;

    setState(() => _isSendingInvite = true);

    final friend = context
        .read<SocialCubit>()
        .state
        .friends
        .firstWhere((f) => f.friendId == _selectedFriend);

    try {
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

      await context.read<SocialCubit>().sendGameInvite(_selectedFriend, gameConfig);

      if (mounted) {
        setState(() => _isSendingInvite = false);

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(locale.get('play_friend_invite_sent')),
            content: Text(
              '${locale.get('play_friend_waiting_response')}${friend.friendNickname}...',
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.pop(); // Возвращаемся назад
                },
                child: Text(locale.get('play_friend_ok')),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSendingInvite = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${locale.get('play_friend_invite_error')}$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}