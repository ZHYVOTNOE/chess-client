abstract class UserSettings {
  String get language;
  String get boardTheme;
  String get pieceTheme;
}

class UserSettingsImpl implements UserSettings {
  @override
  final String language;
  @override
  final String boardTheme;
  @override
  final String pieceTheme;

  UserSettingsImpl({
    required this.language,
    required this.boardTheme,
    required this.pieceTheme,
  });
}
