import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:client/core/error/exceptions.dart';
import '../../domain/entities/puzzle.dart';

abstract class PuzzleRemoteDataSource {
  Future<Puzzle> getRandomPuzzle({
    required int userRating,
    String? theme,
  });

  Future<Puzzle> getPuzzleById(String puzzleId);

  Future<List<Puzzle>> getPuzzlesByTheme({
    required String theme,
    int limit = 20,
    int offset = 0,
  });

  Future<bool> submitSolution({
    required String puzzleId,
    required List<String> moves,
  });

  Future<int> getUserPuzzleRating(String userId);

  Future<void> savePuzzleAttempt({
    required String userId,
    required String puzzleId,
    required bool isSolved,
  });

  Future<Map<String, dynamic>> getUserStats();

  Future<List<String>> getThemes();
}

class PuzzleRemoteDataSourceImpl implements PuzzleRemoteDataSource {
  final SupabaseClient client;

  PuzzleRemoteDataSourceImpl(this.client);

  @override
  Future<Puzzle> getRandomPuzzle({
    required int userRating,
    String? theme,
  }) async {
    final userId = client.auth.currentUser?.id;
    print('=== userId: $userId, userRating: $userRating');

    final response = await client.rpc('get_random_puzzle', params: {
      'p_user_id': userId,
      'p_user_rating': userRating,
    });

    print('=== RPC response: $response');
    print('=== response type: ${response.runtimeType}');

    if (response == null || (response is List && response.isEmpty)) {
      throw ServerException('No puzzles found in rating range');
    }

    final puzzleData = response is List ? response.first : response;
    return Puzzle.fromJson(puzzleData);
    // Внешний catch в loadPuzzle поймает любую ошибку с деталями
  }

  @override
  Future<Puzzle> getPuzzleById(String puzzleId) async {
    try {
      final response = await client
          .from('puzzles')
          .select('*')
          .eq('PuzzleId', puzzleId)
          .single();

      return Puzzle.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to fetch puzzle');
    }
  }

  @override
  Future<List<Puzzle>> getPuzzlesByTheme({
    required String theme,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final query = client.from('puzzles').select('*');

      if (theme != 'all') {
        query.ilike('Themes', '%$theme%');
      }

      final response = await query
          .order('Rating', ascending: true)
          .range(offset, offset + limit - 1);

      return (response as List).map((json) => Puzzle.fromJson(json)).toList();
    } catch (e) {
      throw ServerException();
    }
  }

  Future<int> getUserPuzzleRating(String userId) async {
    try {
      final response = await client
          .from('ratings')
          .select('rating')
          .eq('user_id', userId)
          .eq('variant_key', 'puzzles')
          .single();

      return response['rating'] as int? ?? 1500;
    } catch (e) {
      return 1500;
    }
  }

  @override
  Future<bool> submitSolution({
    required String puzzleId,
    required List<String> moves,
  }) async {
    try {
      // Validate the solution by comparing with the puzzle's correct moves
      final puzzle = await getPuzzleById(puzzleId);
      final solutionMoves = puzzle.moves;

      if (moves.length != solutionMoves.length) {
        return false;
      }

      for (int i = 0; i < moves.length; i++) {
        if (moves[i] != solutionMoves[i]) {
          return false;
        }
      }

      // Record the solved puzzle using RPC function
      final userId = client.auth.currentUser?.id;
      if (userId != null) {
        await client.rpc('save_puzzle_attempt', params: {
          'p_user_id': userId,
          'p_puzzle_id': puzzleId,
          'p_is_solved': true,
        });
      }

      return true;
    } catch (e) {
      throw ServerException('Failed to submit solution');
    }
  }

  Future<void> savePuzzleAttempt({
    required String userId,
    required String puzzleId,
    required bool isSolved,
  }) async {
    try {
      await client.rpc('save_puzzle_attempt', params: {
        'p_user_id': userId,
        'p_puzzle_id': puzzleId,
        'p_is_solved': isSolved,
      });
    } catch (e) {
      throw ServerException('Failed to save puzzle attempt');
    }
  }

  @override
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        return {'rating': 1500, 'streak': 0, 'solved_today': 0, 'solved_total': 0};
      }

      final puzzleRating = await getUserPuzzleRating(userId);

      int solvedTotal = 0;
      int solvedToday = 0;
      int streak = 0;

      try {
        final solvedResponse = await client
            .from('user_puzzle_attempts')
            .select('puzzle_id')
            .eq('user_id', userId)
            .eq('is_solved', true);
        solvedTotal = solvedResponse.length;
      } catch (e) {
        print('=== getUserStats: solvedTotal error: $e');
      }

      try {
        final today = DateTime.now();
        final startOfDay = DateTime(today.year, today.month, today.day).toIso8601String();
        final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59).toIso8601String();

        final solvedTodayResponse = await client
            .from('user_puzzle_attempts')
            .select('puzzle_id')
            .eq('user_id', userId)
            .eq('is_solved', true)
            .gte('last_attempt_at', startOfDay)
            .lte('last_attempt_at', endOfDay);
        solvedToday = solvedTodayResponse.length;
      } catch (e) {
        print('=== getUserStats: solvedToday error: $e');
      }

      try {
        streak = await _calculateStreak(userId);
      } catch (e) {
        print('=== getUserStats: streak error: $e');
      }

      return {
        'rating': puzzleRating,
        'streak': streak,
        'solved_today': solvedToday,
        'solved_total': solvedTotal,
      };
    } catch (e) {
      print('=== getUserStats failed: $e');
      return {'rating': 1500, 'streak': 0, 'solved_today': 0, 'solved_total': 0};
    }
  }

  Future<int> _calculateStreak(String userId) async {
    try {
      // Get all solved puzzles grouped by date
      final response = await client
          .from('user_puzzle_attempts')
          .select('last_attempt_at')
          .eq('user_id', userId)
          .eq('is_solved', true)
          .order('last_attempt_at', ascending: false)
          .limit(365); // Last year

      final dates = response
          .map((r) => DateTime.parse(r['last_attempt_at'] as String))
          .map((d) => DateTime(d.year, d.month, d.day))
          .toSet()
          .toList()
        ..sort((a, b) => b.millisecondsSinceEpoch.compareTo(a.millisecondsSinceEpoch));

      if (dates.isEmpty) return 0;

      int streak = 1;
      final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      final yesterday = today.subtract(const Duration(days: 1));

      // Check if the most recent day is today or yesterday
      if (dates.first != today && dates.first != yesterday) {
        return 0;
      }

      for (int i = 0; i < dates.length - 1; i++) {
        final current = dates[i];
        final next = dates[i + 1];
        final difference = current.difference(next).inDays;

        if (difference == 1) {
          streak++;
        } else {
          break;
        }
      }

      return streak;
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<List<String>> getThemes() async {
    try {
      // Get unique themes from puzzles
      final response = await client
          .from('puzzles')
          .select('Themes')
          .not('Themes', 'is', null);

      final themes = <String>{};
      for (final row in response) {
        final themesString = row['Themes'] as String?;
        if (themesString != null) {
          final themeList = themesString.split(',');
          for (final theme in themeList) {
            themes.add(theme.trim());
          }
        }
      }

      return themes.toList()..sort();
    } catch (e) {
      throw ServerException('Failed to fetch themes');
    }
  }
}
