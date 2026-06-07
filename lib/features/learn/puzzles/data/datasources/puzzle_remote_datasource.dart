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
    try {
      final query = client.from('puzzles').select('*');

      // Filter by theme if specified
      if (theme != null && theme != 'all') {
        query.ilike('Themes', '%$theme%');
      }

      // Filter by rating range (user rating ± 200)
      final minRating = userRating - 200;
      final maxRating = userRating + 200;
      query.gte('Rating', minRating).lte('Rating', maxRating);

      // Order by popularity and limit to 1
      final response = await query
          .order('Popularity', ascending: false)
          .limit(1)
          .single();

      return Puzzle.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to fetch puzzle');
    }
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

      // Record the solved puzzle in user_puzzle_solutions table
      final userId = client.auth.currentUser?.id;
      if (userId != null) {
        await client.from('user_puzzle_solutions').insert({
          'user_id': userId,
          'puzzle_id': puzzleId,
          'solved_at': DateTime.now().toIso8601String(),
        });
      }

      return true;
    } catch (e) {
      throw ServerException('Failed to submit solution');
    }
  }

  @override
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        return {
          'rating': 1500,
          'streak': 0,
          'solved_today': 0,
        };
      }

      // Get user's puzzle rating from profiles table
      final profileResponse = await client
          .from('profiles')
          .select('puzzle_rating')
          .eq('id', userId)
          .single();

      final puzzleRating = profileResponse['puzzle_rating'] as int? ?? 1500;

      // Get today's solved puzzles count
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day).toIso8601String();
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59).toIso8601String();

      final solvedResponse = await client
          .from('user_puzzle_solutions')
          .select('id')
          .eq('user_id', userId)
          .gte('solved_at', startOfDay)
          .lte('solved_at', endOfDay);

      final solvedToday = solvedResponse.length;

      // Get current streak (consecutive days with at least one solved puzzle)
      final streak = await _calculateStreak(userId);

      return {
        'rating': puzzleRating,
        'streak': streak,
        'solved_today': solvedToday,
      };
    } catch (e) {
      throw ServerException('Failed to fetch user stats');
    }
  }

  Future<int> _calculateStreak(String userId) async {
    try {
      // Get all solved puzzles grouped by date
      final response = await client
          .from('user_puzzle_solutions')
          .select('solved_at')
          .eq('user_id', userId)
          .order('solved_at', ascending: false)
          .limit(365); // Last year

      final dates = response
          .map((r) => DateTime.parse(r['solved_at'] as String))
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
