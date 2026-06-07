import 'dart:io';
import '../../../play/domain/entities/rating.dart' as play_entities;
import '../../../play/domain/repositories/rating_repository.dart';

import '../datasources/profile_remote_datasource.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/entities/profile_user.dart';
import '../../domain/entities/profile_user_impl.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDatasource remote;
  final RatingRepository _ratingRepository;

  ProfileRepositoryImpl(this.remote, this._ratingRepository);

  Rating _convertRating(play_entities.Rating playRating) {
    return RatingImpl(
      variant: playRating.variant,
      timeControl: playRating.timeControl,
      rating: playRating.rating,
      lastPlayedAt: playRating.lastPlayedAt,
    );
  }

  // lib/features/profile/data/repositories/profile_repository_impl.dart

  // lib/features/profile/data/repositories/profile_repository_impl.dart

  @override
  Future<UserProfile> getProfile(String userId) async {
    print('🔍 [ProfileRepository] getProfile called for userId: $userId');

    final model = await remote.getProfile(userId);
    print('📄 [ProfileRepository] Profile model loaded');

    final playRatings = await _ratingRepository.getUserRatings(userId);
    print('📊 [ProfileRepository] Fetched ${playRatings.length} ratings from play feature');

    final ratingsMap = <String, Rating>{};
    for (final r in playRatings) {
      // ✅ Если time_control пустой, используем только variant
      final key = r.timeControl.isEmpty
          ? r.variant  // "puzzles"
          : '${r.variant}_${r.timeControl}'; // "standard_blitz"

      print('🗺️ [ProfileRepository] Mapping rating - key: $key, variant: ${r.variant}, timeControl: ${r.timeControl}, rating: ${r.rating}');
      ratingsMap[key] = _convertRating(r);
    }

    print('🎯 [ProfileRepository] Final ratings map keys: ${ratingsMap.keys.toList()}');
    print('🎯 [ProfileRepository] Puzzles rating: ${ratingsMap['puzzles']?.rating ?? "NOT FOUND"}');

    final profileWithRatings = model.copyWith(ratings: ratingsMap);
    return profileWithRatings.toEntity();
  }

  @override
  Future<void> updateNickname(String userId, String nickname) =>
      remote.updateNickname(userId, nickname);

  @override
  Future<void> updateAvatar(String userId, File file) async {
    final url = await remote.uploadAvatar(userId, file);
    await remote.updateAvatarUrl(userId, url);
  }

  @override
  Future<void> updateFullName(String userId, String? fullName) =>
      remote.updateFullName(userId, fullName);

  @override
  Future<void> updateBio(String userId, String? bio) =>
      remote.updateBio(userId, bio);

  @override
  Future<void> updateCountryCode(String userId, String? countryCode) =>
      remote.updateCountryCode(userId, countryCode);

  @override
  Future<bool> isNicknameAvailable(String nickname, String currentUserId) async {
    return await remote.isNicknameAvailable(nickname, currentUserId);
  }

  @override
  Future<UserProfile> updateProfile(String userId, Map<String, dynamic> data) async {
    final model = await remote.updateProfile(userId, data);
    return model.toEntity();
  }
}