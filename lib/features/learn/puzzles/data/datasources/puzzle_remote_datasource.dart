import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:client/core/error/exceptions.dart';
import '../../domain/entities/puzzle.dart';

abstract class PuzzleRemoteDataSource {
  Future<Puzzle> getRandomPuzzle({required int userRating, String? theme});
  Future<Puzzle> getPuzzleById(String puzzleId);
  Future<List<Puzzle>> getPuzzlesByTheme({required String theme, int limit = 20, int offset = 0});
  Future<bool> submitSolution({required String puzzleId, required List<String> moves});
  Future<int> getUserPuzzleRating(String userId);
  Future<void> savePuzzleAttempt({required String userId, required String puzzleId, required bool isSolved});
  Future<Map<String, dynamic>> getUserStats();
  Future<List<String>> getThemes();
}

class PuzzleRemoteDataSourceImpl implements PuzzleRemoteDataSource {
  final SupabaseClient client;

  PuzzleRemoteDataSourceImpl(this.client);

  @override
  Future<Puzzle> getRandomPuzzle({required int userRating, String? theme}) async {
    final userId = client.auth.currentUser?.id;

    final response = await client.rpc('get_random_puzzle', params: {
      'p_user_id': userId,
      'p_user_rating': userRating,
    });

    if (response == null || (response is List && response.isEmpty)) {
      throw ServerException('No puzzles found in rating range');
    }

    final puzzleData = response is List ? response.first : response;
    return Puzzle.fromJson(puzzleData);
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
      if (theme != 'all') query.ilike('Themes', '%$theme%');
      final response = await query
          .order('Rating', ascending: true)
          .range(offset, offset + limit - 1);
      return (response as List).map((json) => Puzzle.fromJson(json)).toList();
    } catch (e) {
      throw ServerException();
    }
  }

  @override
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
      final puzzle = await getPuzzleById(puzzleId);
      final solutionMoves = puzzle.moves;

      if (moves.length != solutionMoves.length) return false;
      for (int i = 0; i < moves.length; i++) {
        if (moves[i] != solutionMoves[i]) return false;
      }

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

  @override
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
        return {'rating': 1500, 'current_streak': 0, 'solved_today': 0};
      }

      final result = await client.rpc('get_puzzle_stats', params: {
        'p_user_id': userId,
      });

      if (result != null) {
        return Map<String, dynamic>.from(result as Map);
      }

      return {'rating': 1500, 'current_streak': 0, 'solved_today': 0};
    } catch (e) {
      print('=== getUserStats failed: $e');
      return {'rating': 1500, 'current_streak': 0, 'solved_today': 0};
    }
  }

  @override
  Future<List<String>> getThemes() async {
    try {
      final response = await client
          .from('puzzles')
          .select('Themes')
          .not('Themes', 'is', null);

      final themes = <String>{};
      for (final row in response) {
        final themesString = row['Themes'] as String?;
        if (themesString != null) {
          for (final theme in themesString.split(' ')) {
            if (theme.trim().isNotEmpty) themes.add(theme.trim());
          }
        }
      }
      return themes.toList()..sort();
    } catch (e) {
      throw ServerException('Failed to fetch themes');
    }
  }
}