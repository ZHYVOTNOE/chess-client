import '../repositories/profile_repository.dart';

class UpdateBio {
  final ProfileRepository repository;

  UpdateBio(this.repository);

  Future<void> call(String userId, String? bio) async {
    if (bio != null && bio.length > 255) {
      throw FormatException('Bio must be 255 characters or less');
    }
    await repository.updateBio(userId, bio);
  }
}
