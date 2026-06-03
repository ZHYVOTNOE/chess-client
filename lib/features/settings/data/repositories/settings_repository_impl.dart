import '../datasources/settings_remote_datasource.dart';
import '../../domain/entities/user_settings.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsRemoteDataSource remote;

  SettingsRepositoryImpl(this.remote);

  @override
  Future<UserSettings> getSettings(String userId) async {
    final model = await remote.getSettings(userId);
    return UserSettingsImpl(
      language: model.language,
      boardTheme: model.boardTheme,
      pieceTheme: model.pieceSet,
    );
  }

  @override
  Future<void> updateSettings(String userId, UserSettings settings) async {
    final settingsJson = <String, dynamic>{
      'language': settings.language,
      'board_theme': settings.boardTheme,
      'piece_set': settings.pieceTheme,
    };
    await remote.updateSettings(userId, settingsJson);
  }
}
