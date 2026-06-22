import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../features/settings/data/models/user_settings_model.dart';
import '../../features/settings/data/repositories/settings_repository.dart';

class SettingsProvider extends ChangeNotifier {
  final SettingsRepository _repository;
  UserSettingsModel? _settings;
  bool _isLoading = false;
  Timer? _saveTimer;

  SettingsProvider(this._repository);

  UserSettingsModel? get settings => _settings;
  bool get isLoading => _isLoading;

  /// Загрузка при старте или смене пользователя
  Future<void> loadSettings(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _settings = await _repository.getSettings(userId);
      debugPrint('✅ [Settings] Loaded: boardTheme=${_settings?.boardTheme}, pieceSet=${_settings?.pieceSet}');
    } catch (e) {
      debugPrint('❌ [Settings] Load error: $e');
      _settings = UserSettingsModel(userId: userId); // Фолбэк
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Debounce-сохранение в БД (ждем 1 сек после последнего изменения)
  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 1), () async {
      if (_settings != null) {
        try {
          await _repository.upsertSettings(_settings!);
          debugPrint('✅ [Settings] Auto-saved');
        } catch (e) {
          debugPrint('❌ [Settings] Save error: $e');
        }
      }
    });
  }

  // 🔥 Сеттеры с автосохранением
  void setBoardTheme(String id) {
    debugPrint('🎨 [Settings] Setting boardTheme to: $id');
    _update((s) => s.copyWith(boardTheme: id));
  }
  void setPieceSet(String id) {
    debugPrint('♟️ [Settings] Setting pieceSet to: $id');
    _update((s) => s.copyWith(pieceSet: id));
  }
  void setPieceSize(double size) => _update((s) => s.copyWith(pieceSize: size));
  void setShowCoordinates(bool val) => _update((s) => s.copyWith(showCoordinates: val));
  void setHighlightLastMove(bool val) => _update((s) => s.copyWith(highlightLastMove: val));
  void setHighlightPossibleMoves(bool val) => _update((s) => s.copyWith(highlightPossibleMoves: val));
  void setSoundEnabled(bool val) => _update((s) => s.copyWith(soundEnabled: val));
  void setSoundSet(String set) => _update((s) => s.copyWith(soundSet: set));
  void setVibrationEnabled(bool val) => _update((s) => s.copyWith(vibrationEnabled: val));
  void setVibrationIntensity(String intensity) => _update((s) => s.copyWith(vibrationIntensity: intensity));

  /// Внутренний хелпер для обновления состояния
  void _update(UserSettingsModel Function(UserSettingsModel s) builder) {
    if (_settings == null) return;
    _settings = builder(_settings!);
    _scheduleSave();
    notifyListeners();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }
}