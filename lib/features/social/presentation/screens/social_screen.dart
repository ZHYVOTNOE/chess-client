import 'package:bishop/bishop.dart' as bishop;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../play/domain/entities/player_color.dart';
import '../cubits/social_cubit.dart';
import '../../domain/entities/friend.dart';
import '../../../play/domain/entities/game_config.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

// 🔥 ДОБАВЛЕНО: with SingleTickerProviderStateMixin
class _SocialScreenState extends State<SocialScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  int get _selectedTab => _tabController.index;

  // Game setup dialog state
  String _selectedTime = '10|0';
  bool _rated = true;
  String _chosenColor = 'random';

  @override
  void initState() {
    super.initState();
    // Инициализируем контроллер с количеством вкладок (3)
    _tabController = TabController(length: 3, vsync: this);

    // Слушаем изменения индекса, чтобы обновлять UI (если нужно)
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SocialCubit, SocialState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Social'),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Friends'),
                Tab(text: 'Search'),
                Tab(text: 'Requests'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildFriendsList(state.friends),
              _buildSearchTab(state),
              _buildRequestsList(state.friendRequests, state.sentRequests),
            ],
          ),
          floatingActionButton: _selectedTab == 0 && state.gameInvites.isNotEmpty
              ? FloatingActionButton(
            onPressed: () => _showInvitationDialog(context, state.gameInvites.first),
            child: const Icon(Icons.mail),
          )
              : null,
        );
      },
    );
  }

  Widget _buildFriendsList(List<Friend> friends) {
    if (friends.isEmpty) {
      return const Center(child: Text('No friends yet'));
    }

    return ListView.separated(
      itemCount: friends.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final friend = friends[index];
        return InkWell(
          onTap: () => _viewProfile(friend),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  key: ValueKey('friend_${friend.friendId}_${friend.friendAvatarUrl}'),
                  radius: 28,
                  backgroundImage: friend.friendAvatarUrl != null
                      ? NetworkImage(friend.friendAvatarUrl!)
                      : null,
                  child: friend.friendAvatarUrl == null
                      ? Text(
                    friend.friendNickname.isNotEmpty ? friend.friendNickname[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friend.friendNickname,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (friend.friendFullName != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          friend.friendFullName!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                      if (friend.friendBio != null && friend.friendBio!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          friend.friendBio!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'play') {
                      context.go('/game/friend', extra: {'friend': friend});
                    } else if (value == 'remove') {
                      _removeFriend(friend);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'play',
                      child: Row(
                        children: [
                          Icon(Icons.play_arrow),
                          SizedBox(width: 8),
                          Text('Играть'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Удалить', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchTab(SocialState state) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search users (ID or nickname)',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: state.isSearching
                  ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
                  : IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  context.read<SocialCubit>().searchUsers('');
                },
              ),
            ),
            onChanged: (value) {
              context.read<SocialCubit>().searchUsers(value);
            },
          ),
        ),
        Expanded(
          child: state.isSearching
              ? const Center(child: CircularProgressIndicator())
              : state.searchResults.isEmpty
              ? const Center(child: Text('No users found'))
              : ListView.separated(
            itemCount: state.searchResults.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final user = state.searchResults[index];
              return InkWell(
                onTap: () => _viewProfile(user),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        key: ValueKey('search_${user.friendId}_${user.friendAvatarUrl}'),
                        radius: 28,
                        backgroundImage: user.friendAvatarUrl != null
                            ? NetworkImage(user.friendAvatarUrl!)
                            : null,
                        child: user.friendAvatarUrl == null
                            ? Text(
                          user.friendNickname.isNotEmpty ? user.friendNickname[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.friendNickname,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (user.friendFullName != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                user.friendFullName!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                            if (user.friendBio != null && user.friendBio!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                user.friendBio!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      // 🔥 ИСПРАВЛЕНО: Заменяем IconButton на динамический виджет
                      _buildSearchAction(state, user),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // 🔥 НОВЫЙ МЕТОД: Определяет, какую иконку показать в поиске
  Widget _buildSearchAction(SocialState state, Friend user) {
    // Проверяем, есть ли этот пользователь уже в друзьях
    bool isFriend = state.friends.any((f) => f.friendId == user.friendId);
    // Проверяем, отправлен ли уже ему запрос
    bool isSent = state.sentRequests.any((r) => r.friendId == user.friendId);

    if (isFriend) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Icon(Icons.check_circle, color: Colors.green, semanticLabel: 'Already friends'),
      );
    } else if (isSent) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Icon(Icons.hourglass_empty, color: Colors.orange, semanticLabel: 'Request sent'),
      );
    } else {
      return IconButton(
        icon: const Icon(Icons.person_add),
        onPressed: () => _sendFriendRequest(user),
      );
    }
  }

  Widget _buildRequestsList(List<Friend> incomingRequests, List<Friend> sentRequests) {
    if (incomingRequests.isEmpty && sentRequests.isEmpty) {
      return const Center(child: Text('No pending requests'));
    }

    return ListView(
      children: [
        // Incoming Requests Section
        if (incomingRequests.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Входящие запросы',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ...List.generate(incomingRequests.length, (index) {
            return Column(
              children: [
                _buildIncomingRequestTile(incomingRequests[index]),
                if (index < incomingRequests.length - 1) const Divider(height: 1),
              ],
            );
          }),
          const Divider(height: 32),
        ],
        // Sent Requests Section
        if (sentRequests.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Исходящие запросы',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ...List.generate(sentRequests.length, (index) {
            return Column(
              children: [
                _buildSentRequestTile(sentRequests[index]),
                if (index < sentRequests.length - 1) const Divider(height: 1),
              ],
            );
          }),
        ],
      ],
    );
  }

  Widget _buildIncomingRequestTile(Friend request) {
    return InkWell(
      onTap: () => _viewProfile(request),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              key: ValueKey('incoming_${request.friendId}_${request.friendAvatarUrl}'),
              radius: 28,
              backgroundImage: request.friendAvatarUrl != null
                  ? NetworkImage(request.friendAvatarUrl!)
                  : null,
              child: request.friendAvatarUrl == null
                  ? Text(
                request.friendNickname.isNotEmpty ? request.friendNickname[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.friendNickname,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (request.friendFullName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      request.friendFullName!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                  if (request.friendBio != null && request.friendBio!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      request.friendBio!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () => _acceptFriendRequest(request),
                  tooltip: 'Accept',
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => _declineFriendRequest(request),
                  tooltip: 'Decline',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentRequestTile(Friend request) {
    return InkWell(
      onTap: () => _viewProfile(request),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              key: ValueKey('sent_${request.friendId}_${request.friendAvatarUrl}'),
              radius: 28,
              backgroundImage: request.friendAvatarUrl != null
                  ? NetworkImage(request.friendAvatarUrl!)
                  : null,
              child: request.friendAvatarUrl == null
                  ? Text(
                request.friendNickname.isNotEmpty ? request.friendNickname[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.friendNickname,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (request.friendFullName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      request.friendFullName!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                  if (request.friendBio != null && request.friendBio!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      request.friendBio!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () => _cancelSentRequest(request),
              tooltip: 'Cancel',
            ),
          ],
        ),
      ),
    );
  }

  void _inviteToGame(Friend friend) {
    _selectedTime = '10|0';
    _rated = true;
    _chosenColor = 'random';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Invite ${friend.friendNickname}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Time Control', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _TimeOption(
                      code: '1|0',
                      name: '1+0',
                      isSelected: _selectedTime == '1|0',
                      onTap: () => setDialogState(() => _selectedTime = '1|0'),
                    ),
                    _TimeOption(
                      code: '3|0',
                      name: '3+0',
                      isSelected: _selectedTime == '3|0',
                      onTap: () => setDialogState(() => _selectedTime = '3|0'),
                    ),
                    _TimeOption(
                      code: '5|0',
                      name: '5+0',
                      isSelected: _selectedTime == '5|0',
                      onTap: () => setDialogState(() => _selectedTime = '5|0'),
                    ),
                    _TimeOption(
                      code: '10|0',
                      name: '10+0',
                      isSelected: _selectedTime == '10|0',
                      onTap: () => setDialogState(() => _selectedTime = '10|0'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Color', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _ColorOption(
                      code: 'white',
                      name: 'White',
                      isSelected: _chosenColor == 'white',
                      onTap: () => setDialogState(() => _chosenColor = 'white'),
                    ),
                    _ColorOption(
                      code: 'random',
                      name: 'Random',
                      isSelected: _chosenColor == 'random',
                      onTap: () => setDialogState(() => _chosenColor = 'random'),
                    ),
                    _ColorOption(
                      code: 'black',
                      name: 'Black',
                      isSelected: _chosenColor == 'black',
                      onTap: () => setDialogState(() => _chosenColor = 'black'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Rated game'),
                  subtitle: const Text('Affects your rating'),
                  value: _rated,
                  onChanged: (v) => setDialogState(() => _rated = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);

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

                  await context.read<SocialCubit>().sendGameInvite(friend.friendId, gameConfig);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Invitation sent to ${friend.friendNickname}')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to send invite: $e')),
                    );
                  }
                }
              },
              child: const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }

  void _removeFriend(Friend friend) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove friend'),
        content: Text('Are you sure you want to remove ${friend.friendNickname}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<SocialCubit>().removeFriend(friend.id);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _sendFriendRequest(Friend user) {
    context.read<SocialCubit>().sendFriendRequest(user.friendId, knownProfile: user);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Friend request sent to ${user.friendNickname}')),
    );
  }

  void _acceptFriendRequest(Friend request) {
    context.read<SocialCubit>().acceptFriendRequest(request.id);
  }

  void _declineFriendRequest(Friend request) {
    context.read<SocialCubit>().declineFriendRequest(request.id);
  }

  void _cancelSentRequest(Friend request) {
    context.read<SocialCubit>().cancelSentRequest(request.id);
  }

  void _viewProfile(Friend friend) {
    context.push('/profile', extra: {
      'userId': friend.friendId,
      'isReadOnly': true,
    });
  }

  void _showInvitationDialog(BuildContext context, Map<String, dynamic> invite) {
    final profile = invite['profiles'] as Map<String, dynamic>?;
    final nickname = profile?['nickname'] ?? 'Unknown';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Game invitation from $nickname'),
        content: const Text('Do you want to accept this game invitation?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<SocialCubit>().declineGameInvite(invite['id']);
            },
            child: const Text('Decline'),
          ),
          TextButton(
            onPressed: () async {
              final gameId = await context.read<SocialCubit>().acceptGameInvite(invite['id']);
              if (gameId != null && mounted) {
                Navigator.pop(context);

                // Get game data to determine player colors
                try {
                  final inviteData = invite;
                  final fromUserId = inviteData['from_user_id'] as String?;
                  final currentUserId = inviteData['to_user_id'] as String?;

                  if (fromUserId != null && currentUserId != null) {
                    // Determine colors based on invite config or random
                    final gameConfig = inviteData['game_config'] as Map<String, dynamic>?;
                    final colorChoice = gameConfig?['color'] as String? ?? 'random';

                    String? whiteId, blackId;
                    if (colorChoice == 'white') {
                      whiteId = currentUserId;
                      blackId = fromUserId;
                    } else if (colorChoice == 'black') {
                      whiteId = fromUserId;
                      blackId = currentUserId;
                    } else {
                      // Random assignment
                      final isWhite = DateTime.now().millisecond % 2 == 0;
                      whiteId = isWhite ? currentUserId : fromUserId;
                      blackId = isWhite ? fromUserId : currentUserId;
                    }

                    final config = GameConfig.create(
                      variant: bishop.Variant.standard(),
                      gameId: gameId,
                      humanPlayer: whiteId == currentUserId ? PlayerColor.white : PlayerColor.black,
                      opponentType: OpponentType.human,
                    );

                    if (mounted) {
                      context.push(
                        '/board',
                        extra: {
                          'config': config,
                          'gameId': gameId,
                          'whiteId': whiteId,
                          'blackId': blackId,
                        },
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to start game: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }
}

class _TimeOption extends StatelessWidget {
  final String code;
  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimeOption({
    required this.code,
    required this.name,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          name,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _ColorOption extends StatelessWidget {
  final String code;
  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorOption({
    required this.code,
    required this.name,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            name,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}