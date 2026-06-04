import '../repositories/profile_repository.dart';

class CheckNicknameAvailability {
  final ProfileRepository repository;

  CheckNicknameAvailability(this.repository);

  Future<bool> call(String nickname, String currentUserId) async {
    if (nickname.trim().length < 3) {
      throw FormatException('Nickname must be at least 3 characters');
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(nickname)) {
      throw FormatException('Nickname can only contain letters, numbers, and underscores');
    }

    return await repository.isNicknameAvailable(nickname, currentUserId);
  }
}