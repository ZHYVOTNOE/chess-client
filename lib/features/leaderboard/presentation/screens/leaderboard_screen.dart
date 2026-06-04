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

  void _onScroll() {
    if (!mounted) return;

    final state = context.read<LeaderboardCubit>().state;
    final userRank = state.userRank;
    final currentUserEntry = state.currentUserEntry;

    if (userRank == null || currentUserEntry == null) return;

    // Check if user is in the visible list
    final userInList = state.leaderboardEntries.any((e) => e.userId == currentUserEntry.userId);

    if (!userInList) {
      // User not in Top 50, show sticky row at bottom by default
      setState(() {
        _showStickyRowAtBottom = true;
        _showStickyRowAtTop = false;
      });
      return;
    }

    // User is in the list, implement sticky row logic
    final scrollPosition = _scrollController.position.pixels;
    final userIndex = state.leaderboardEntries.indexWhere((e) => e.userId == currentUserEntry.userId);
    final itemHeight = 72.0; // Approximate height of list item
    final userPosition = userIndex * itemHeight;

    // If scrolled past user's position, stick to top
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
    return Column(
      children: [
        // Category filter
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: LeaderboardCubit.categories.length,
            itemBuilder: (context, index) {
              final category = LeaderboardCubit.categories[index];
              final isSelected = state.selectedCategory == category;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FilterChip(
                  label: Text(_formatCategoryName(category)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      context.read<LeaderboardCubit>().changeCategory(category);
                    }
                  },
                  selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                  checkmarkColor: Theme.of(context).primaryColor,
                ),
              );
            },
          ),
        ),
        // Scope filter
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: LeaderboardCubit.scopes.length,
            itemBuilder: (context, index) {
              final scope = LeaderboardCubit.scopes[index];
              final isSelected = state.selectedScope == scope;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FilterChip(
                  label: Text(_formatScopeName(scope)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      context.read<LeaderboardCubit>().changeScope(scope);
                    }
                  },
                  selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                  checkmarkColor: Theme.of(context).primaryColor,
                ),
              );
            },
          ),
        ),
        const Divider(height: 1),
      ],
    );
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
    return Container(
      height: 72,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundImage: entry.avatarUrl != null
              ? NetworkImage(entry.avatarUrl!)
              : null,
          child: entry.avatarUrl == null
              ? Text(
                  entry.nickname.isNotEmpty ? entry.nickname[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                )
              : null,
        ),
        title: Row(
          children: [
            SizedBox(
              width: 40,
              child: Text(
                '#${entry.rank}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            if (entry.title != null) ...[
              Text(
                entry.title!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                entry.nickname,
                style: const TextStyle(fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            if (entry.countryCode != null) ...[
              Text(_getCountryFlag(entry.countryCode!)),
              const SizedBox(width: 8),
            ],
            Text(
              entry.rating.toStringAsFixed(0),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        trailing: entry.variantKey != 'standard'
            ? Text(
                _formatCategoryName(entry.variantKey),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              )
            : null,
      ),
    );
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
            color: Colors.black.withValues(alpha: 0.1),
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
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: _buildLeaderboardItem(context, entry.copyWith(rank: state.userRank ?? 0)),
    );
  }

  String _formatCategoryName(String category) {
    switch (category) {
      case 'bullet':
        return 'Bullet';
      case 'blitz':
        return 'Blitz';
      case 'rapid':
        return 'Rapid';
      case 'puzzles':
        return 'Puzzles';
      case 'chess960':
        return 'Chess960';
      case 'kingOfTheHill':
        return 'King of the Hill';
      default:
        return category[0].toUpperCase() + category.substring(1);
    }
  }

  String _formatScopeName(String scope) {
    switch (scope) {
      case 'global':
        return 'Global';
      case 'country':
        return 'Country';
      case 'friends':
        return 'Friends';
      default:
        return scope[0].toUpperCase() + scope.substring(1);
    }
  }

  String _getCountryFlag(String countryCode) {
    // Simple flag emoji mapping (can be expanded)
    final flagMap = {
      'US': '🇺🇸',
      'RU': '🇷🇺',
      'UA': '🇺🇦',
      'DE': '🇩🇪',
      'GB': '🇬🇧',
      'FR': '🇫🇷',
      'ES': '🇪🇸',
      'IT': '🇮🇹',
      'CN': '🇨🇳',
      'IN': '🇮🇳',
      'BR': '🇧🇷',
      'JP': '🇯🇵',
      'KR': '🇰🇷',
    };
    return flagMap[countryCode.toUpperCase()] ?? '🏳️';
  }
}
