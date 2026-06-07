import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/usecases/get_leaderboard_usecase.dart';
import '../../domain/usecases/get_user_rank_usecase.dart';
import '../../domain/repositories/leaderboard_repository.dart';
import '../cubits/leaderboard_state.dart';

class LeaderboardCubit extends Cubit<LeaderboardState> {
  final GetLeaderboardUseCase _getLeaderboardUseCase;
  final GetUserRankUseCase _getUserRankUseCase;
  final LeaderboardRepository _repository;
  final SupabaseClient _supabase;

  static const List<String> categories = [
    'bullet',
    'blitz',
    'rapid',
    'puzzles',
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

  static const List<String> scopes = ['global', 'country', 'friends'];

  LeaderboardCubit(
    this._getLeaderboardUseCase,
    this._getUserRankUseCase,
    this._repository,
    this._supabase,
  ) : super(LeaderboardState.initial()) {
    _initialize();
  }

  Future<void> _initialize() async {
    await loadLeaderboard();
    await loadUserRank();
  }

  Future<void> loadLeaderboard() async {
    emit(state.copyWith(
      isLoading: true,
      error: null,
      currentOffset: 0,
      leaderboardEntries: [],
    ));

    try {
      final entries = await _getLeaderboardUseCase(
        category: state.selectedCategory,
        scope: state.selectedScope,
        offset: 0,
        limit: 50,
      );

      final hasMore = entries.length >= 50;

      emit(state.copyWith(
        leaderboardEntries: entries,
        isLoading: false,
        hasMore: hasMore,
        currentOffset: entries.length,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    emit(state.copyWith(isLoading: true));

    try {
      final entries = await _getLeaderboardUseCase(
        category: state.selectedCategory,
        scope: state.selectedScope,
        offset: state.currentOffset,
        limit: 50,
      );

      final hasMore = entries.length >= 50;

      emit(state.copyWith(
        leaderboardEntries: [...state.leaderboardEntries, ...entries],
        isLoading: false,
        hasMore: hasMore,
        currentOffset: state.currentOffset + entries.length,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> changeCategory(String category) async {
    if (state.selectedCategory == category) return;

    emit(state.copyWith(selectedCategory: category));
    await loadLeaderboard();
    await loadUserRank();
  }

  Future<void> changeScope(String scope) async {
    if (state.selectedScope == scope) return;

    emit(state.copyWith(selectedScope: scope));
    await loadLeaderboard();
  }

  Future<void> loadUserRank() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final rank = await _getUserRankUseCase(
        category: state.selectedCategory,
        userId: userId,
      );

      final userEntry = await _repository.getCurrentUserEntry(
        category: state.selectedCategory,
        userId: userId,
      );

      emit(state.copyWith(
        userRank: rank,
        currentUserEntry: userEntry,
      ));
    } catch (e) {
      // Don't emit error for rank loading, just set to null
      emit(state.copyWith(
        userRank: null,
        currentUserEntry: null,
      ));
    }
  }

  void clearError() {
    emit(state.copyWith(error: null));
  }
}
