import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/location_service.dart';
import '../../../play/data/datasources/ratings_remote_datasource.dart';
import '../../../play/domain/repositories/rating_repository.dart';
import '../../../play/data/models/rating_model.dart' as play_models;
import '../../data/datasources/profile_remote_datasource.dart';
import '../../domain/entities/profile_user.dart';
import '../../domain/entities/profile_user_impl.dart';
import '../../domain/usecases/check_nickname_availability_usecase.dart';
import '../../domain/usecases/get_profile_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import '../../domain/usecases/update_full_name_usecase.dart';
import '../../domain/usecases/update_bio_usecase.dart';
import '../../domain/usecases/update_country_code_usecase.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final GetProfile getProfile;
  final UpdateNickname updateNickname;
  final UpdateAvatar updateAvatar;
  final UpdateFullName updateFullName;
  final UpdateBio updateBio;
  final UpdateCountryCode updateCountryCode;
  final UpdateProfile _updateProfileUseCase;
  final CheckNicknameAvailability _checkNicknameAvailability;
  final LocationService locationService;
  final RatingRepository _ratingRepository;
  final RatingsRemoteDataSource _ratingsDataSource;

  StreamSubscription? _ratingsSubscription;

  ProfileCubit(
      this.getProfile,
      this.updateNickname,
      this.updateAvatar,
      this.updateFullName,
      this.updateBio,
      this.updateCountryCode,
      this._updateProfileUseCase,
      this._checkNicknameAvailability,
      this.locationService,
      this._ratingRepository,
      this._ratingsDataSource,
      ) : super(ProfileInitial());

  Rating _modelToProfileRating(play_models.RatingModel model) {
    return RatingImpl(
      variant: model.variant,
      timeControl: model.timeControl,
      rating: model.rating,
      lastPlayedAt: model.lastPlayedAt,
    );
  }

  Rating _playRatingToProfileRating(dynamic playRating) {
    return RatingImpl(
      variant: playRating.variant,
      timeControl: playRating.timeControl,
      rating: playRating.rating,
      lastPlayedAt: playRating.lastPlayedAt,
    );
  }

  // lib/features/profile/presentation/cubits/profile_cubit.dart

  Future<void> loadProfile(String userId) async {
    emit(ProfileLoading());
    try {
      final profile = await getProfile(userId);
      print('📄 [ProfileCubit] Profile loaded for user $userId');
      print('🎯 [ProfileCubit] Profile ratings keys: ${profile.ratings?.keys.toList()}');
      print('🎯 [ProfileCubit] Puzzles rating: ${profile.ratings?['puzzles']?.rating ?? "NOT FOUND"}');

      emit(ProfileLoaded(profile));

      _subscribeToRatingsUpdates(userId);
    } catch (e) {
      print('❌ [ProfileCubit] Error loading profile: $e');
      emit(ProfileError(e.toString()));
    }
  }

  void _subscribeToRatingsUpdates(String userId) {
    _ratingsSubscription?.cancel();

    _ratingsSubscription = _ratingsDataSource
        .ratingsStream(userId)
        .listen((updatedRatings) async {
      print('🔄 [ProfileCubit] Ratings stream update - count: ${updatedRatings.length}');

      final currentState = state;
      if (currentState is ProfileLoaded || currentState is ProfileUpdated) {
        final currentProfile = currentState is ProfileLoaded
            ? currentState.profile
            : (currentState as ProfileUpdated).profile;

        final ratingsMap = <String, Rating>{};
        for (final ratingModel in updatedRatings) {
          final key = ratingModel.timeControl.isEmpty
              ? ratingModel.variant
              : '${ratingModel.variant}_${ratingModel.timeControl}';

          print('🗺️ [ProfileCubit] Stream mapping - key: $key, rating: ${ratingModel.rating}');
          ratingsMap[key] = _modelToProfileRating(ratingModel);
        }

        print('🎯 [ProfileCubit] Stream - Puzzles rating: ${ratingsMap['puzzles']?.rating ?? "NOT FOUND"}');

        final updatedProfile = currentProfile.copyWith(ratings: ratingsMap);
        emit(ProfileUpdated(updatedProfile));
      }
    }, onError: (error) {
      print('❌ [ProfileCubit] Error in ratings stream: $error');
    });
  }

  Future<void> refreshRatings(String userId) async {
    try {
      final currentState = state;
      if (currentState is ProfileLoaded || currentState is ProfileUpdated) {
        final currentProfile = currentState is ProfileLoaded
            ? currentState.profile
            : (currentState as ProfileUpdated).profile;

        final playRatings = await _ratingRepository.getUserRatings(userId);

        // Конвертируем play.Rating -> RatingImpl
        final ratingsMap = <String, Rating>{
          for (final r in playRatings)
            '${r.variant}_${r.timeControl}': _playRatingToProfileRating(r),
        };

        final updatedProfile = currentProfile.copyWith(ratings: ratingsMap);
        emit(ProfileUpdated(updatedProfile));
      }
    } catch (e) {
      debugPrint('❌ Failed to refresh ratings: $e');
    }
  }

  Future<void> changeNickname(String userId, String nickname) async {
    try {
      await updateNickname(userId, nickname);
      final profile = await getProfile(userId);
      emit(ProfileUpdated(profile));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  // 🔥 ИСПРАВЛЕНО: используем use case вместо несуществующего _repository
  Future<void> changeAvatar(String userId, File file) async {
    emit(ProfileLoading());
    try {
      await updateAvatar(userId, file);  // Вызываем use case

      // Перечитываем профиль, чтобы получить новый URL с таймстемпом
      await loadProfile(userId);

      // Invalidate image cache for the old avatar
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      // Evict old avatar from cache if we have the old URL
      final currentState = state;
      if (currentState is ProfileLoaded && currentState.profile.avatarUrl != null) {
        final oldAvatarUrl = currentState.profile.avatarUrl!;
        try {
          await NetworkImage(oldAvatarUrl).evict();
          debugPrint('🗑️ Evicted old avatar from cache: $oldAvatarUrl');
        } catch (e) {
          debugPrint('⚠️ Failed to evict old avatar: $e');
        }
      }

      debugPrint('✅ Avatar changed and profile reloaded for user: $userId');
    } catch (e) {
      debugPrint('❌ Avatar change error: $e');
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> changeFullName(String userId, String? fullName) async {
    try {
      await updateFullName(userId, fullName);
      final profile = await getProfile(userId);
      emit(ProfileUpdated(profile));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> changeBio(String userId, String? bio) async {
    try {
      await updateBio(userId, bio);
      final profile = await getProfile(userId);
      emit(ProfileUpdated(profile));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> changeCountryCode(String userId, String? countryCode) async {
    try {
      await updateCountryCode(userId, countryCode);
      final profile = await getProfile(userId);
      emit(ProfileUpdated(profile));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> updateCountryViaGPS(String userId) async {
    emit(ProfileLoading());
    try {
      final countryCode = await locationService.getCountryCode();
      if (countryCode != null) {
        await updateCountryCode(userId, countryCode);
        final profile = await getProfile(userId);
        emit(ProfileUpdated(profile));
      } else {
        emit(ProfileError('Could not determine country from GPS'));
      }
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<bool> checkNicknameAvailability(String nickname, String currentUserId) async {
    return await _checkNicknameAvailability(nickname, currentUserId);
  }

  Future<void> updateProfile(String userId, UserProfile updatedProfile) async {
    emit(ProfileLoading());
    try {
      final data = <String, dynamic>{};
      data['nickname'] = updatedProfile.nickname;
      if (updatedProfile.fullName != null) data['full_name'] = updatedProfile.fullName;
      if (updatedProfile.bio != null) data['bio'] = updatedProfile.bio;
      if (updatedProfile.countryCode != null) data['country_code'] = updatedProfile.countryCode;

      await _updateProfileUseCase(userId, data);
      await loadProfile(userId);
    } catch (e) {
      // 🔥 БД тоже защищена — ловим ошибку уникальности как последний рубеж
      if (e is NicknameAlreadyTakenException) {
        emit(ProfileError('Этот никнейм уже занят'));
      } else {
        emit(ProfileError(e.toString()));
      }
    }
  }

  @override
  Future<void> close() {
    _ratingsSubscription?.cancel();
    return super.close();
  }
}