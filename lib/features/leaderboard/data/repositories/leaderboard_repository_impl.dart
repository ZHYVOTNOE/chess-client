import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/repositories/leaderboard_repository.dart';
import '../models/leaderboard_model.dart';

class LeaderboardRepositoryImpl implements LeaderboardRepository {
  final SupabaseClient _supabase;

  LeaderboardRepositoryImpl(this._supabase);

  @override
  Future<List<LeaderboardEntry>> getLeaderboard({
    required String category,
    required String scope,
    int offset = 0,
    int limit = 50,
  }) async {
    // 1. Создаем начальный фильтр-билдер
    PostgrestFilterBuilder query = _supabase.from('leaderboard').select();

    // 2. Применяем фильтры категории
    query = _applyCategoryFilter(query, category);

    // 3. Применяем фильтры области (мир/страна/друзья)
    query = await _applyScopeFilter(query, scope);

    // 4. В самом конце добавляем сортировку и диапазон
    final response = await query
        .order('rating', ascending: false)
        .range(offset, offset + limit - 1);

    final entries = <LeaderboardEntry>[];
    for (int i = 0; i < (response as List).length; i++) {
      final model = LeaderboardModel.fromJson(response[i]);
      final entry = model.toEntity().copyWith(rank: offset + i + 1);
      entries.add(entry);
    }

    return entries;
  }

  @override
  Future<int> getUserRank({
    required String category,
    required String userId,
  }) async {
    final userEntry = await getCurrentUserEntry(category: category, userId: userId);
    if (userEntry == null) return 0;

    final userRating = userEntry.rating;

    PostgrestFilterBuilder query = _supabase.from('leaderboard').select('user_id');

    query = _applyCategoryFilter(query, category);

    // Считаем количество игроков с рейтингом выше нашего
    final response = await query.gt('rating', userRating);

    return (response as List).length + 1;
  }

  @override
  Future<String?> getCurrentUserCountryCode(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('country_code')
          .eq('id', userId)
          .single();

      return response['country_code'] as String?;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<LeaderboardEntry?> getCurrentUserEntry({
    required String category,
    required String userId,
  }) async {
    PostgrestFilterBuilder query = _supabase.from('leaderboard').select().eq('user_id', userId);

    query = _applyCategoryFilter(query, category);

    try {
      final response = await query.single();
      final model = LeaderboardModel.fromJson(response);
      return model.toEntity();
    } catch (e) {
      return null;
    }
  }

  // Вспомогательный метод для фильтрации по категориям
  PostgrestFilterBuilder _applyCategoryFilter(PostgrestFilterBuilder query, String category) {
    switch (category) {
      case 'bullet':
        return query.eq('variant_key', 'standard').eq('time_control_type', 'bullet');
      case 'blitz':
        return query.eq('variant_key', 'standard').eq('time_control_type', 'blitz');
      case 'rapid':
        return query.eq('variant_key', 'standard').eq('time_control_type', 'rapid');
      case 'puzzles':
        return query.eq('variant_key', 'puzzles');
      default:
      // Для шахматных вариантов (chess960 и т.д.)
        return query.eq('variant_key', category);
    }
  }

  // Вспомогательный метод для фильтрации по области видимости
  Future<PostgrestFilterBuilder> _applyScopeFilter(PostgrestFilterBuilder query, String scope) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return query;

    switch (scope) {
      case 'global':
        return query;
      case 'country':
        final countryCode = await getCurrentUserCountryCode(currentUserId);
        if (countryCode != null) {
          return query.eq('country_code', countryCode);
        }
        return query;
      case 'friends':
        // Fetch friends where current user is the requester
        final friendshipsAsUser = await _supabase
            .from('friendships')
            .select('friend_id')
            .eq('user_id', currentUserId)
            .eq('status', 'accepted');

        // Fetch friends where current user is the recipient (bidirectional)
        final friendshipsAsFriend = await _supabase
            .from('friendships')
            .select('user_id')
            .eq('friend_id', currentUserId)
            .eq('status', 'accepted');

        // Combine friend IDs from both directions
        final friendIds = <String>{};

        for (final f in friendshipsAsUser as List) {
          friendIds.add(f['friend_id'] as String);
        }

        for (final f in friendshipsAsFriend as List) {
          friendIds.add(f['user_id'] as String);
        }

        // Crucial: Add current user to the list
        friendIds.add(currentUserId);

        // Convert to list for the filter
        final combinedIds = friendIds.toList();

        return query.inFilter('user_id', combinedIds);
      default:
        return query;
    }
  }
}
