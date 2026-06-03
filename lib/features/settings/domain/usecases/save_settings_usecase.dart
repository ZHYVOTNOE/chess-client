import '../entities/user_settings.dart';
import '../repositories/settings_repository.dart';

class SaveSettings {
  final SettingsRepository repository;

  SaveSettings(this.repository);

  Future<void> call(String userId, UserSettings settings) {
    return repository.updateSettings(userId, settings);
  }
}
