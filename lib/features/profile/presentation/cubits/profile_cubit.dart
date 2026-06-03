// lib/features/profile/presentation/cubits/profile_cubit.dart
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/location_service.dart';
import '../../domain/entities/profile_user.dart';
import '../../domain/usecases/get_profile_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import '../../domain/usecases/update_full_name_usecase.dart';
import '../../domain/usecases/update_bio_usecase.dart';
import '../../domain/usecases/update_country_code_usecase.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final GetProfile getProfile;
  final UpdateNickname updateNickname;
  final UpdateAvatar updateAvatar;  // Это use case, а не репозиторий
  final UpdateFullName updateFullName;
  final UpdateBio updateBio;
  final UpdateCountryCode updateCountryCode;
  final UpdateProfile _updateProfileUseCase;
  final LocationService locationService;

  ProfileCubit(
      this.getProfile,
      this.updateNickname,
      this.updateAvatar,
      this.updateFullName,
      this.updateBio,
      this.updateCountryCode,
      this._updateProfileUseCase,
      this.locationService,
      ) : super(ProfileInitial());

  Future<void> loadProfile(String userId) async {
    emit(ProfileLoading());
    try {
      final profile = await getProfile(userId);
      debugPrint('📄 Profile loaded for user $userId, avatarUrl: ${profile.avatarUrl}');
      emit(ProfileLoaded(profile));
    } catch (e) {
      emit(ProfileError(e.toString()));
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

  Future<void> updateProfile(String userId, UserProfile updatedProfile) async {
    emit(ProfileLoading());
    try {
      final data = <String, dynamic>{};
      data['nickname'] = updatedProfile.nickname;
      if (updatedProfile.fullName != null) data['full_name'] = updatedProfile.fullName;
      if (updatedProfile.bio != null) data['bio'] = updatedProfile.bio;
      if (updatedProfile.countryCode != null) data['country_code'] = updatedProfile.countryCode;

      await _updateProfileUseCase(userId, data);
      
      // Force reload from database to get fresh data including avatar_url
      await loadProfile(userId);
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }
}