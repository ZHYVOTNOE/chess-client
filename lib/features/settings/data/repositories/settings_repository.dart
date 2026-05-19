import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_settings_model.dart';

class SettingsRepository {
  final SupabaseClient _client;

  SettingsRepository(this._client);

  /// Загрузка настроек пользователя
  Future<UserSettingsModel> getSettings(String userId) async {
    final response = await _client
        .from('user_settings')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) {
      // Если записи нет, возвращаем дефолтные настройки
      return UserSettingsModel(userId: userId);
    }

    // Supabase возвращает { user_id, settings: { ... }, updated_at }
    final settingsJson = Map<String, dynamic>.from(response['settings'] ?? {});
    return UserSettingsModel.fromJson(userId, settingsJson);
  }

  /// Сохранение/обновление настроек (upsert)
  Future<void> upsertSettings(UserSettingsModel settings) async {
    await _client.from('user_settings').upsert({
      'user_id': settings.userId,
      'settings': settings.toJson(),
    });
  }
}