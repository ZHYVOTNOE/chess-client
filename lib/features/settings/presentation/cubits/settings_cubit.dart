import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../domain/entities/user_settings.dart';
import '../../domain/usecases/get_settings_usecase.dart';
import '../../domain/usecases/save_settings_usecase.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final GetSettings getSettings;
  final SaveSettings saveSettings;
  final LocaleProvider localeProvider;
  final SettingsProvider settingsProvider;

  SettingsCubit(
    this.getSettings,
    this.saveSettings,
    this.localeProvider,
    this.settingsProvider,
  ) : super(SettingsInitial());

  Future<void> loadSettings(String userId) async {
    emit(SettingsLoading());
    try {
      final settings = await getSettings(userId);
      emit(SettingsLoaded(settings));
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  Future<void> updateLanguage(String userId, String language, {BuildContext? context}) async {
    final currentState = state;
    if (currentState is! SettingsLoaded) return;

    // Update local state immediately for instant UI feedback
    final updatedSettings = UserSettingsImpl(
      language: language,
      boardTheme: currentState.settings.boardTheme,
      pieceTheme: currentState.settings.pieceTheme,
    );
    emit(SettingsLoaded(updatedSettings));

    // Save to database in background
    try {
      await saveSettings(userId, updatedSettings);
      
      // CRITICAL: Update LocaleProvider for instant UI switch
      await localeProvider.setLocale(language);
      
      // Show visual confirmation
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localeProvider.get('settings_saved')),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  Future<void> updateBoardTheme(String userId, String boardTheme, {BuildContext? context}) async {
    final currentState = state;
    if (currentState is! SettingsLoaded) return;

    // Update local state immediately for instant UI feedback
    final updatedSettings = UserSettingsImpl(
      language: currentState.settings.language,
      boardTheme: boardTheme,
      pieceTheme: currentState.settings.pieceTheme,
    );
    emit(SettingsLoaded(updatedSettings));

    // Update SettingsProvider for board screens
    debugPrint('🎨 [SettingsCubit] Updating boardTheme to: $boardTheme');
    settingsProvider.setBoardTheme(boardTheme);
    
    // Force notify listeners to ensure boards rebuild
    settingsProvider.notifyListeners();

    // Save to database in background
    try {
      await saveSettings(userId, updatedSettings);
      
      // Show visual confirmation
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localeProvider.get('settings_saved')),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  Future<void> updatePieceTheme(String userId, String pieceTheme, {BuildContext? context}) async {
    final currentState = state;
    if (currentState is! SettingsLoaded) return;

    // Update local state immediately for instant UI feedback
    final updatedSettings = UserSettingsImpl(
      language: currentState.settings.language,
      boardTheme: currentState.settings.boardTheme,
      pieceTheme: pieceTheme,
    );
    emit(SettingsLoaded(updatedSettings));

    // Update SettingsProvider for board screens
    debugPrint('♟️ [SettingsCubit] Updating pieceSet to: $pieceTheme');
    settingsProvider.setPieceSet(pieceTheme);
    
    // Force notify listeners to ensure boards rebuild
    settingsProvider.notifyListeners();

    // Save to database in background
    try {
      await saveSettings(userId, updatedSettings);
      
      // Show visual confirmation
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localeProvider.get('settings_saved')),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }
}
