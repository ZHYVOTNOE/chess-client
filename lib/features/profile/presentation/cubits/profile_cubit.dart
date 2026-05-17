// lib/features/profile/presentation/cubits/profile_cubit.dart
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart'; // ✅ Обязательно!
import '../../domain/usecases/get_profile_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final GetProfile getProfile;
  final UpdateNickname updateNickname;
  final UpdateAvatar updateAvatar;

  ProfileCubit(this.getProfile, this.updateNickname,  this.updateAvatar) : super(ProfileInitial());

  // 🔥 Методы ДОЛЖНЫ быть внутри класса (между { и })
  Future<void> loadProfile(String userId) async {
    emit(ProfileLoading()); // ✅ emit доступен, потому что мы внутри класса
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
      rethrow; // 🔥 Пробрасываем для обработки в UI
    }
  }
}