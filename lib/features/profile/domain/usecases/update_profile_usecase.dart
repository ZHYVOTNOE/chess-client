import 'dart:io';

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
    if (!imageFile.path.endsWith('.jpg') &&
        !imageFile.path.endsWith('.jpeg') &&
        !imageFile.path.endsWith('.png')) {
      throw FormatException('Only JPG and PNG images are allowed');
    }
    if (await imageFile.length() > 5 * 1024 * 1024) {
      throw FormatException('Image must be less than 5MB');
    }
    await repository.updateAvatar(userId, imageFile);
  }
}