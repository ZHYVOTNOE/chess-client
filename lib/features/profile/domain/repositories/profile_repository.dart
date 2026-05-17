import 'dart:io';
import '../entities/profile_user.dart';

abstract class ProfileRepository {
  Future<UserProfile> getProfile(String userId);
  Future<void> updateNickname(String userId, String nickname);
  Future<void> updateAvatar(String userId, File imageFile);
}