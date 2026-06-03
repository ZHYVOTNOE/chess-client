import 'dart:io';
import 'package:path/path.dart' as path;

import '../entities/profile_user.dart';
import '../repositories/profile_repository.dart';

class UpdateNickname {
  final ProfileRepository repository;

  UpdateNickname(this.repository);

  Future<void> call(String userId, String nickname) async {
    if (nickname.trim().length < 3) {
      throw FormatException('Nickname must be at least 3 characters');
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(nickname)) {
      throw FormatException('Nickname can only contain letters, numbers, and underscores');
    }
    await repository.updateNickname(userId, nickname.trim());
  }
}

class UpdateAvatar {
  final ProfileRepository repository;

  UpdateAvatar(this.repository);

  Future<void> call(String userId, File imageFile) async {
    // 🔥 ИСПРАВЛЕНО: используем path.extension для надежной проверки
    final ext = path.extension(imageFile.path).toLowerCase();
    final allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp'];

    if (!allowedExtensions.contains(ext)) {
      throw FormatException('Only JPG, PNG and WebP images are allowed (got: $ext)');
    }

    if (await imageFile.length() > 5 * 1024 * 1024) {
      throw FormatException('Image must be less than 5MB');
    }

    await repository.updateAvatar(userId, imageFile);
  }
}

class UpdateProfile {
  final ProfileRepository repository;

  UpdateProfile(this.repository);

  Future<UserProfile> call(String userId, Map<String, dynamic> data) async {
    if (data.containsKey('bio') && data['bio'] != null) {
      final bio = data['bio'] as String;
      if (bio.length > 255) {
        throw FormatException('Bio must be 255 characters or less');
      }
    }

    return await repository.updateProfile(userId, data);
  }
}