import '../entities/user_settings.dart';
import '../repositories/settings_repository.dart';

class GetSettings {
  final SettingsRepository repository;

  GetSettings(this.repository);

  Future<UserSettings> call(String userId) {
    return repository.getSettings(userId);
  }
}
