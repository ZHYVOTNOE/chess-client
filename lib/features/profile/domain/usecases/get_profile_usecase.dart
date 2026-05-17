import '../entities/profile_user.dart';
import '../repositories/profile_repository.dart';

class GetProfile {
  final ProfileRepository repository;
  GetProfile(this.repository);

  Future<UserProfile> call(String userId) => repository.getProfile(userId);
}