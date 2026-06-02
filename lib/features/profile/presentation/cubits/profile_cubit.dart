// lib/features/profile/presentation/cubits/profile_cubit.dart
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
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
  final UpdateAvatar updateAvatar;
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

  Future<void> changeAvatar(String userId, File imageFile) async {
    emit(ProfileLoading());
    try {
      await updateAvatar(userId, imageFile);
      final profile = await getProfile(userId);
      emit(ProfileUpdated(profile));
    } catch (e) {
      emit(ProfileError(e.toString()));
      rethrow;
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
      
      final profile = await _updateProfileUseCase(userId, data);
      emit(ProfileLoaded(profile));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }
}