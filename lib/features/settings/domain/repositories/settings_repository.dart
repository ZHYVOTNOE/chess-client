import '../entities/user_settings.dart';

abstract class SettingsRepository {
  Future<UserSettings> getSettings(String userId);
  Future<void> updateSettings(String userId, UserSettings settings);
}
