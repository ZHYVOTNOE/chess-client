import 'dart:io';
import '../entities/profile_user.dart';

abstract class ProfileRepository {
  Future<UserProfile> getProfile(String userId);
  Future<bool> isNicknameAvailable(String nickname, String currentUserId);
  Future<void> updateNickname(String userId, String nickname);
  Future<void> updateAvatar(String userId, File imageFile);
  Future<void> updateFullName(String userId, String? fullName);
  Future<void> updateBio(String userId, String? bio);
  Future<void> updateCountryCode(String userId, String? countryCode);
  Future<UserProfile> updateProfile(String userId, Map<String, dynamic> data);
}