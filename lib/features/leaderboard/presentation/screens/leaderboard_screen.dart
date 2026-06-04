import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../cubits/leaderboard_cubit.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../cubits/leaderboard_state.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showStickyRowAtTop = false;
  bool _showStickyRowAtBottom = true;

  String? _selectedCategory;
  String? _selectedScope;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // 👇 МЕТОД ДЛЯ ГЕНЕРАЦИИ ФЛАГА СТРАНЫ
  String _getCountryFlag(String? countryCode) {
    if (countryCode == null || countryCode.isEmpty) return '';
    final code = countryCode.toUpperCase();
    if (code.length != 2) return '';
    final firstLetter = code.codeUnitAt(0) - 0x41 + 0x1F1E6;
    final secondLetter = code.codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCode(firstLetter) + String.fromCharCode(secondLetter);
  }

  void _onScroll() {
    if (!mounted) return;

    final state = context.read<LeaderboardCubit>().state;
    final userRank = state.userRank;
    final currentUserEntry = state.currentUserEntry;

    if (userRank == null || currentUserEntry == null) return;

    final userInList = state.leaderboardEntries.any((e) => e.userId == currentUserEntry.userId);

    if (!userInList) {
      setState(() {
        _showStickyRowAtBottom = true;
        _showStickyRowAtTop = false;
      });
      return;
    }

    final scrollPosition = _scrollController.position.pixels;
    final userIndex = state.leaderboardEntries.indexWhere((e) => e.userId == currentUserEntry.userId);
    final itemHeight = 60.0;
    final userPosition = userIndex * itemHeight;

    if (scrollPosition > userPosition) {
      setState(() {
        _showStickyRowAtTop = true;
        _showStickyRowAtBottom = false;
      });
    } else {
      setState(() {
        _showStickyRowAtTop = false;
        _showStickyRowAtBottom = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LeaderboardCubit, LeaderboardState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            title: const Text('Leaderboard'),
          ),
          body: Column(
            children: [
              _buildFilterBar(context, state),
              Expanded(
                child: Stack(
                  children: [
                    _buildLeaderboardList(context, state),
                    if (_showStickyRowAtTop && state.currentUserEntry != null)
                      _buildStickyRowAtTop(context, state.currentUserEntry!),
                  ],
                ),
              ),
              if (_showStickyRowAtBottom && state.currentUserEntry != null)
                _buildStickyRowAtBottom(context, state.currentUserEntry!),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterBar(BuildContext context, LeaderboardState state) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildDropdown(
              label: 'Scope',
              value: _selectedScope ?? state.selectedScope,
              items: _getScopeItems(),
              onChanged: (value) {
                setState(() => _selectedScope = value);
                context.read<LeaderboardCubit>().changeScope(value!);
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildDropdown(
              label: 'Category',
              value: _selectedCategory ?? state.selectedCategory,
              items: _getCategoryItems(),
              onChanged: (value) {
                setState(() => _selectedCategory = value);
                context.read<LeaderboardCubit>().changeCategory(value!);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey, size: 20),
          style: TextStyle(
            color: Colors.grey.shade800,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _getCategoryItems() {
    return const [
      DropdownMenuItem(value: 'bullet', child: Text('Bullet')),
      DropdownMenuItem(value: 'blitz', child: Text('Blitz')),
      DropdownMenuItem(value: 'rapid', child: Text('Rapid')),
      DropdownMenuItem(value: 'puzzles', child: Text('Puzzles')),
      DropdownMenuItem(value: 'chess960', child: Text('Chess960')),
      DropdownMenuItem(value: 'mini', child: Text('Mini')),
      DropdownMenuItem(value: 'micro', child: Text('Micro')),
      DropdownMenuItem(value: 'nano', child: Text('Nano')),
      DropdownMenuItem(value: 'grand', child: Text('Grand')),
      DropdownMenuItem(value: 'capablanca', child: Text('Capablanca')),
      DropdownMenuItem(value: 'crazyhouse', child: Text('Crazyhouse')),
      DropdownMenuItem(value: 'seirawan', child: Text('Seirawan')),
      DropdownMenuItem(value: 'atomic', child: Text('Atomic')),
      DropdownMenuItem(value: 'kingOfTheHill', child: Text('King of the Hill')),
      DropdownMenuItem(value: 'horde', child: Text('Horde')),
    ];
  }

  List<DropdownMenuItem<String>> _getScopeItems() {
    return const [
      DropdownMenuItem(value: 'global', child: Text('Global')),
      DropdownMenuItem(value: 'country', child: Text('Country')),
      DropdownMenuItem(value: 'friends', child: Text('Friends')),
    ];
  }

  Widget _buildLeaderboardList(BuildContext context, LeaderboardState state) {
    if (state.isLoading && state.leaderboardEntries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.leaderboardEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: ${state.error}'),
            ElevatedButton(
              onPressed: () => context.read<LeaderboardCubit>().loadLeaderboard(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.leaderboardEntries.isEmpty) {
      return const Center(child: Text('No entries found'));
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.extentAfter < 200 &&
            state.hasMore &&
            !state.isLoading) {
          context.read<LeaderboardCubit>().loadMore();
        }
        return false;
      },
      child: ListView.builder(
        controller: _scrollController,
        itemCount: state.leaderboardEntries.length + (state.isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.leaderboardEntries.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final entry = state.leaderboardEntries[index];
          return _buildLeaderboardItem(context, entry);
        },
      ),
    );
  }

  Widget _buildLeaderboardItem(BuildContext context, LeaderboardEntry entry) {
    final isTopThree = entry.rank <= 3;
    final flag = _getCountryFlag(entry.countryCode);

    Color? rankBackgroundColor;

    if (entry.rank == 1) {
      rankBackgroundColor = const Color(0xFFFFD700);
    } else if (entry.rank == 2) {
      rankBackgroundColor = const Color(0xFFC0C0C0);
    } else if (entry.rank == 3) {
      rankBackgroundColor = const Color(0xFFCD7F32);
    }

    return InkWell(
      onTap: () => _navigateToUserProfile(context, entry.userId),
      child: Container(
        height: 60,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isTopThree ? rankBackgroundColor!.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isTopThree ? rankBackgroundColor!.withOpacity(0.3) : Colors.grey.shade200,
            width: isTopThree ? 1.5 : 1,
          ),
          boxShadow: isTopThree
              ? [
            BoxShadow(
              color: rankBackgroundColor!.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: rankBackgroundColor ?? Colors.grey.shade100, // Светло-серый фон для 4+
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '#${entry.rank}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isTopThree ? Colors.white : Colors.black87, // 👈 ИСПРАВЛЕНО: черный для 4+
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              CircleAvatar(
                radius: 20,
                backgroundImage: entry.avatarUrl != null ? NetworkImage(entry.avatarUrl!) : null,
                backgroundColor: Colors.grey.shade200,
                child: entry.avatarUrl == null
                    ? Text(
                  entry.nickname.isNotEmpty ? entry.nickname[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                )
                    : null,
              ),
              const SizedBox(width: 10),

              // Имя, Титул, Флаг и Полное имя
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        if (entry.title != null && entry.title!.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFB91C1C),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              entry.title!,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.3,
                                height: 1.1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                        ],
                        Flexible( // 👈 Заменяем Expanded на Flexible
                          child: Text(
                            entry.nickname,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (flag.isNotEmpty) ...[
                          const SizedBox(width: 10), // 👈 Отступ 10
                          Text(
                            flag,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ],
                    ),
                    // 👇 ПОЛНОЕ ИМЯ (FULL NAME) СНИЗУ
                    if (entry.fullName != null && entry.fullName!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        entry.fullName!,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Рейтинг
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  entry.rating.toStringAsFixed(0),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToUserProfile(BuildContext context, String userId) {
    context.push('/profile', extra: {'userId': userId, 'isReadOnly': true});
  }

  Widget _buildStickyRowAtTop(BuildContext context, LeaderboardEntry entry) {
    final state = context.read<LeaderboardCubit>().state;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _buildLeaderboardItem(context, entry.copyWith(rank: state.userRank ?? 0)),
    );
  }

  Widget _buildStickyRowAtBottom(BuildContext context, LeaderboardEntry entry) {
    final state = context.read<LeaderboardCubit>().state;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: _buildLeaderboardItem(context, entry.copyWith(rank: state.userRank ?? 0)),
    );
  }
}