import '../repositories/profile_repository.dart';

class UpdateFullName {
  final ProfileRepository repository;

  UpdateFullName(this.repository);

  Future<void> call(String userId, String? fullName) async {
    await repository.updateFullName(userId, fullName);
  }
}
