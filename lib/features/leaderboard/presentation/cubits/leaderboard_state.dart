import '../../domain/entities/leaderboard_entry.dart';

class LeaderboardState {
  final List<LeaderboardEntry> leaderboardEntries;
  final int? userRank;
  final LeaderboardEntry? currentUserEntry;
  final String selectedCategory;
  final String selectedScope;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final int currentOffset;

  LeaderboardState({
    required this.leaderboardEntries,
    this.userRank,
    this.currentUserEntry,
    required this.selectedCategory,
    required this.selectedScope,
    required this.isLoading,
    this.error,
    required this.hasMore,
    required this.currentOffset,
  });

  factory LeaderboardState.initial() {
    return LeaderboardState(
      leaderboardEntries: [],
      userRank: null,
      currentUserEntry: null,
      selectedCategory: 'blitz',
      selectedScope: 'global',
      isLoading: false,
      error: null,
      hasMore: true,
      currentOffset: 0,
    );
  }

  LeaderboardState copyWith({
    List<LeaderboardEntry>? leaderboardEntries,
    int? userRank,
    LeaderboardEntry? currentUserEntry,
    String? selectedCategory,
    String? selectedScope,
    bool? isLoading,
    String? error,
    bool? hasMore,
    int? currentOffset,
  }) {
    return LeaderboardState(
      leaderboardEntries: leaderboardEntries ?? this.leaderboardEntries,
      userRank: userRank ?? this.userRank,
      currentUserEntry: currentUserEntry ?? this.currentUserEntry,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedScope: selectedScope ?? this.selectedScope,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      currentOffset: currentOffset ?? this.currentOffset,
    );
  }
}
