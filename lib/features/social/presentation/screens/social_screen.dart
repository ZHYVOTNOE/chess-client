import 'package:bishop/bishop.dart' as bishop;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/locale_provider.dart';
import '../../../../core/services/presence_service.dart';
import '../../../play/domain/entities/player_color.dart';
import '../cubits/social_cubit.dart';
import '../../domain/entities/friend.dart';
import '../../../play/domain/entities/game_config.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  int get _selectedTab => _tabController.index;

  String _selectedTime = '10|0';
  bool _rated = true;
  String _chosenColor = 'random';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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

  String _getCountryFlag(String? countryCode) {
    if (countryCode == null || countryCode.isEmpty) return '';
    final code = countryCode.toUpperCase();
    if (code.length != 2) return '';
    final firstLetter = code.codeUnitAt(0) - 0x41 + 0x1F1E6;
    final secondLetter = code.codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCode(firstLetter) + String.fromCharCode(secondLetter);
  }

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

  Widget _buildAvatarWithStatus({
    required String? avatarUrl,
    required String fallbackLetter,
    required bool isOnline,
    required Key key,
    double radius = 24,
  }) {
    return Stack(
      children: [
        CircleAvatar(
          key: key,
          radius: radius,
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
          child: avatarUrl == null
              ? Text(
            fallbackLetter.isNotEmpty ? fallbackLetter[0].toUpperCase() : '?',
            style: TextStyle(fontSize: radius * 0.75, fontWeight: FontWeight.bold),
          )
              : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: radius * 0.5,
            height: radius * 0.5,
            decoration: BoxDecoration(
              color: isOnline ? Colors.green : Colors.grey.shade400,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNameRow({
    required String nickname,
    required String? title,
    required String flag,
    double fontSize = 15,
  }) {
    return Row(
      children: [
        if (title != null && title.isNotEmpty) ...[
          TitleBadge(title: title),
          SizedBox(width: 6.0.w),
        ],
        Flexible(
          child: Text(
            nickname,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (flag.isNotEmpty) ...[
          SizedBox(width: 10.0.w),
          Text(flag, style: TextStyle(fontSize: fontSize + 1)),
        ],
      ],
    );
  }

  Widget _buildBioText(String? bio, LocaleProvider locale) {
    if (bio == null || bio.isEmpty) {
      return Text(
        locale.get('social_no_description'),
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade400,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    return Text(
      bio,
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey.shade600,
        fontStyle: FontStyle.italic,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();

    return BlocBuilder<SocialCubit, SocialState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(locale.get('social_title')),
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: locale.get('social_friends')),
                Tab(text: locale.get('social_search')),
                Tab(text: locale.get('social_requests')),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildFriendsList(state.friends, locale),
              _buildSearchTab(state, locale),
              _buildRequestsList(state.friendRequests, state.sentRequests, locale),
            ],
          ),
          floatingActionButton: _selectedTab == 0 && state.gameInvites.isNotEmpty
              ? FloatingActionButton(
            onPressed: () => _showInvitationDialog(context, state.gameInvites.first, locale),
            child: const Icon(Icons.mail),
          )
              : null,
        );
      },
    );
  }

  Widget _buildFriendsList(List<Friend> friends, LocaleProvider locale) {
    if (friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
            SizedBox(height: 16.h),
            Text(
              locale.get('social_no_friends'),
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    // 🔥 СОРТИРОВКА: онлайн первыми, потом по последнему входу
    final sortedFriends = _sortFriends(friends);

    return ListView.separated(
      itemCount: sortedFriends.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final friend = sortedFriends[index];
        final isOnline = PresenceService.isOnline(friend.lastSeenAt);
        final statusText = PresenceService.formatLastSeen(friend.lastSeenAt);
        final flag = _getCountryFlag(friend.countryCode);

        return InkWell(
          onTap: () => _viewProfile(friend),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            child: Row(
              children: [
                _buildAvatarWithStatus(
                  avatarUrl: friend.friendAvatarUrl,
                  fallbackLetter: friend.friendNickname,
                  isOnline: isOnline,
                  key: ValueKey('friend_${friend.friendId}_${friend.friendAvatarUrl}'),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildNameRow(
                        nickname: friend.friendNickname,
                        title: friend.title,
                        flag: flag,
                      ),
                      SizedBox(height: 2.0.h),
                      Row(
                        children: [
                          if (friend.friendFullName != null) ...[
                            Flexible(
                              child: Text(
                                friend.friendFullName!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          SizedBox(width: 30.w),
                          Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 12,
                              color: isOnline ? Colors.green : Colors.grey.shade600,
                              fontWeight: isOnline ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'play') {
                      context.go('/game/friend', extra: {'friend': friend});
                    } else if (value == 'remove') {
                      _removeFriend(friend, locale);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'play',
                      child: Row(
                        children: [
                          const Icon(Icons.play_arrow),
                          const SizedBox(width: 8),
                          Text(locale.get('social_play')),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          const Icon(Icons.delete, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(
                            locale.get('social_remove'),
                            style: const TextStyle(color: Colors.red),
                          ),
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

  Widget _buildSearchTab(SocialState state, LocaleProvider locale) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: locale.get('social_search_hint'),
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
              ? Center(
            child: Text(
              locale.get('social_no_users_found'),
              style: TextStyle(color: Colors.grey.shade600),
            ),
          )
              : ListView.separated(
            itemCount: state.searchResults.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final user = state.searchResults[index];
              final isOnline = PresenceService.isOnline(user.lastSeenAt);
              final flag = _getCountryFlag(user.countryCode);

              return InkWell(
                onTap: () => _viewProfile(user),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                  child: Row(
                    children: [
                      _buildAvatarWithStatus(
                        avatarUrl: user.friendAvatarUrl,
                        fallbackLetter: user.friendNickname,
                        isOnline: isOnline,
                        key: ValueKey('search_${user.friendId}_${user.friendAvatarUrl}'),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildNameRow(
                              nickname: user.friendNickname,
                              title: user.title,
                              flag: flag,
                            ),
                            SizedBox(height: 2.0.h),
                            _buildBioText(user.friendBio, locale),
                          ],
                        ),
                      ),
                      _buildSearchAction(state, user, locale),
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

  Widget _buildSearchAction(SocialState state, Friend user, LocaleProvider locale) {
    final isFriend = state.friends.any((f) => f.friendId == user.friendId);
    final isSent = state.sentRequests.any((r) => r.friendId == user.friendId);
    final isBanned = state.bannedUserIds.contains(user.friendId);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isFriend)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(Icons.check_circle, color: Colors.green),
          )
        else if (isSent)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(Icons.hourglass_empty, color: Colors.orange),
          )
        else
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _sendFriendRequest(user, locale),
          ),

        if (state.isAdmin && !user.isAdmin)
          isBanned
              ? IconButton(
            icon: const Icon(Icons.lock_open, color: Colors.green),
            tooltip: locale.get('social_unban'),
            onPressed: () => _showUnbanDialog(user, locale),
          )
              : IconButton(
            icon: const Icon(Icons.block, color: Colors.red),
            tooltip: locale.get('social_ban'),
            onPressed: () => _showBanDialog(user, locale),
          ),
      ],
    );
  }

  void _showBanDialog(Friend user, LocaleProvider locale) {
    final presets = [
      (locale.get('social_1_hour'), const Duration(hours: 1)),
      (locale.get('social_24_hours'), const Duration(hours: 24)),
      (locale.get('social_7_days'), const Duration(days: 7)),
      (locale.get('social_30_days'), const Duration(days: 30)),
      (locale.get('social_1_year'), const Duration(days: 365)),
      (locale.get('social_forever'), null),
    ];

    int selectedPreset = 1;
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('${locale.get('social_ban_title')}${user.friendNickname}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  locale.get('social_ban_duration'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...List.generate(presets.length, (i) {
                  final (label, _) = presets[i];
                  return RadioListTile<int>(
                    title: Text(label),
                    value: i,
                    groupValue: selectedPreset,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (v) => setDialogState(() => selectedPreset = v!),
                  );
                }),
                const SizedBox(height: 12),
                Text(
                  locale.get('social_reason'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: reasonController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: locale.get('social_ban_reason_hint'),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(locale.get('cancel')),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () async {
                final reason = reasonController.text.trim();
                if (reason.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(locale.get('social_ban_reason_required'))),
                  );
                  return;
                }

                final (_, duration) = presets[selectedPreset];
                final bannedUntil = duration != null ? DateTime.now().add(duration) : null;

                Navigator.pop(context);

                await context.read<SocialCubit>().banUser(
                  userId: user.friendId,
                  reason: reason,
                  bannedUntil: bannedUntil,
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${user.friendNickname}${locale.get('social_banned')}'),
                    ),
                  );
                }
              },
              child: Text(locale.get('social_ban')),
            ),
          ],
        ),
      ),
    );
  }

  void _showUnbanDialog(Friend user, LocaleProvider locale) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${locale.get('social_unban_title')}${user.friendNickname}?'),
        content: Text(locale.get('social_unban_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(locale.get('cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<SocialCubit>().unbanUser(user.friendId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${user.friendNickname}${locale.get('social_unbanned')}')),
                );
              }
            },
            child: Text(locale.get('social_unban')),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsList(
      List<Friend> incomingRequests,
      List<Friend> sentRequests,
      LocaleProvider locale,
      ) {
    if (incomingRequests.isEmpty && sentRequests.isEmpty) {
      return Center(
        child: Text(
          locale.get('social_no_pending_requests'),
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    return ListView(
      children: [
        if (incomingRequests.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              locale.get('social_incoming_requests'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ...List.generate(incomingRequests.length, (index) {
            return Column(
              children: [
                _buildIncomingRequestTile(incomingRequests[index], locale),
                if (index < incomingRequests.length - 1) const Divider(height: 1),
              ],
            );
          }),
          const Divider(height: 32),
        ],
        if (sentRequests.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              locale.get('social_outgoing_requests'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ...List.generate(sentRequests.length, (index) {
            return Column(
              children: [
                _buildSentRequestTile(sentRequests[index], locale),
                if (index < sentRequests.length - 1) const Divider(height: 1),
              ],
            );
          }),
        ],
      ],
    );
  }

  Widget _buildIncomingRequestTile(Friend request, LocaleProvider locale) {
    final isOnline = PresenceService.isOnline(request.lastSeenAt);
    final flag = _getCountryFlag(request.countryCode);

    return InkWell(
      onTap: () => _viewProfile(request),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            _buildAvatarWithStatus(
              avatarUrl: request.friendAvatarUrl,
              fallbackLetter: request.friendNickname,
              isOnline: isOnline,
              key: ValueKey('incoming_${request.friendId}_${request.friendAvatarUrl}'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNameRow(
                    nickname: request.friendNickname,
                    title: request.title,
                    flag: flag,
                  ),
                  const SizedBox(height: 2),
                  _buildBioText(request.friendBio, locale),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () => _acceptFriendRequest(request),
                  tooltip: locale.get('social_accept'),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => _declineFriendRequest(request),
                  tooltip: locale.get('social_decline'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentRequestTile(Friend request, LocaleProvider locale) {
    final isOnline = PresenceService.isOnline(request.lastSeenAt);
    final flag = _getCountryFlag(request.countryCode);

    return InkWell(
      onTap: () => _viewProfile(request),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            _buildAvatarWithStatus(
              avatarUrl: request.friendAvatarUrl,
              fallbackLetter: request.friendNickname,
              isOnline: isOnline,
              key: ValueKey('sent_${request.friendId}_${request.friendAvatarUrl}'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNameRow(
                    nickname: request.friendNickname,
                    title: request.title,
                    flag: flag,
                  ),
                  const SizedBox(height: 2),
                  _buildBioText(request.friendBio, locale),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () => _cancelSentRequest(request),
              tooltip: locale.get('social_cancel'),
            ),
          ],
        ),
      ),
    );
  }

  void _inviteToGame(Friend friend, LocaleProvider locale) {
    _selectedTime = '10|0';
    _rated = true;
    _chosenColor = 'random';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('${locale.get('social_invite_title')}${friend.friendNickname}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  locale.get('social_time_control'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
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
                Text(
                  locale.get('social_color'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _ColorOption(
                      code: 'white',
                      name: locale.get('openings_white'),
                      isSelected: _chosenColor == 'white',
                      onTap: () => setDialogState(() => _chosenColor = 'white'),
                    ),
                    _ColorOption(
                      code: 'random',
                      name: locale.get('quick_random_color'),
                      isSelected: _chosenColor == 'random',
                      onTap: () => setDialogState(() => _chosenColor = 'random'),
                    ),
                    _ColorOption(
                      code: 'black',
                      name: locale.get('openings_black'),
                      isSelected: _chosenColor == 'black',
                      onTap: () => setDialogState(() => _chosenColor = 'black'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: Text(locale.get('social_rated_game')),
                  subtitle: Text(locale.get('social_affects_rating')),
                  value: _rated,
                  onChanged: (v) => setDialogState(() => _rated = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(locale.get('cancel')),
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
                      SnackBar(
                        content: Text(
                          '${locale.get('social_invitation_sent')}${friend.friendNickname}',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${locale.get('social_invite_failed')}$e')),
                    );
                  }
                }
              },
              child: Text(locale.get('social_send')),
            ),
          ],
        ),
      ),
    );
  }

  void _removeFriend(Friend friend, LocaleProvider locale) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(locale.get('social_remove_friend_title')),
        content: Text(
          '${locale.get('social_remove_friend_confirm')}${friend.friendNickname}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(locale.get('cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<SocialCubit>().removeFriend(friend.id);
            },
            child: Text(locale.get('social_remove')),
          ),
        ],
      ),
    );
  }

  void _sendFriendRequest(Friend user, LocaleProvider locale) {
    context.read<SocialCubit>().sendFriendRequest(user.friendId, knownProfile: user);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${locale.get('social_request_sent')}${user.friendNickname}'),
      ),
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

  void _showInvitationDialog(BuildContext context, Map<String, dynamic> invite, LocaleProvider locale) {
    final profile = invite['profiles'] as Map<String, dynamic>?;
    final nickname = profile?['nickname'] ?? 'Unknown';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('${locale.get('social_game_invitation')}$nickname'),
        content: Text(locale.get('social_accept_invitation')),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<SocialCubit>().declineGameInvite(invite['id']);
            },
            child: Text(locale.get('social_decline')),
          ),
          TextButton(
            onPressed: () async {
              final gameId = await context.read<SocialCubit>().acceptGameInvite(invite['id']);
              if (gameId != null && mounted) {
                Navigator.pop(context);
                try {
                  final inviteData = invite;
                  final fromUserId = inviteData['from_user_id'] as String?;
                  final currentUserId = inviteData['to_user_id'] as String?;

                  if (fromUserId != null && currentUserId != null) {
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
                      final isWhite = DateTime.now().millisecond % 2 == 0;
                      whiteId = isWhite ? currentUserId : fromUserId;
                      blackId = isWhite ? fromUserId : currentUserId;
                    }

                    final config = GameConfig.create(
                      variant: bishop.Variant.standard(),
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
                      SnackBar(content: Text('${locale.get('social_game_start_failed')}$e')),
                    );
                  }
                }
              }
            },
            child: Text(locale.get('social_accept')),
          ),
        ],
      ),
    );
  }
}

class TitleBadge extends StatelessWidget {
  final String title;
  const TitleBadge({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFFB91C1C),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
          height: 1.2,
        ),
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