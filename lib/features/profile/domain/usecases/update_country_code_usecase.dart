import '../repositories/profile_repository.dart';

class UpdateCountryCode {
  final ProfileRepository repository;

  UpdateCountryCode(this.repository);

  Future<void> call(String userId, String? countryCode) async {
    await repository.updateCountryCode(userId, countryCode);
  }
}
