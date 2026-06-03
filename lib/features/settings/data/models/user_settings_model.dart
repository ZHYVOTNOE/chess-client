class UserSettingsModel {
  final String userId;

  // Language
  final String language;

  // Доска
  final String boardTheme;
  final bool showCoordinates;
  final bool highlightLastMove;
  final bool highlightPossibleMoves;

  // Фигуры
  final String pieceSet;
  final double pieceSize;

  // Звуки
  final bool soundEnabled;
  final String soundSet;

  // Вибрация
  final bool vibrationEnabled;
  final String vibrationIntensity;

  const UserSettingsModel({
    required this.userId,
    this.language = 'ru',
    this.boardTheme = 'classic',
    this.showCoordinates = true,
    this.highlightLastMove = true,
    this.highlightPossibleMoves = true,
    this.pieceSet = 'merida',
    this.pieceSize = 1.0,
    this.soundEnabled = true,
    this.soundSet = 'default',
    this.vibrationEnabled = true,
    this.vibrationIntensity = 'medium',
  });

  factory UserSettingsModel.fromJson(String userId, Map<String, dynamic> json) {
    return UserSettingsModel(
      userId: userId,
      language: json['language'] ?? 'ru', // COALESCE with default for backward compatibility
      boardTheme: json['board_theme'] ?? 'classic',
      showCoordinates: json['show_coordinates'] ?? true,
      highlightLastMove: json['highlight_last_move'] ?? true,
      highlightPossibleMoves: json['highlight_possible_moves'] ?? true,
      pieceSet: json['piece_set'] ?? 'merida',
      pieceSize: (json['piece_size'] ?? 1.0).toDouble(),
      soundEnabled: json['sound_enabled'] ?? true,
      soundSet: json['sound_set'] ?? 'default',
      vibrationEnabled: json['vibration_enabled'] ?? true,
      vibrationIntensity: json['vibration_intensity'] ?? 'medium',
    );
  }

  Map<String, dynamic> toJson() => {
    'language': language,
    'board_theme': boardTheme,
    'show_coordinates': showCoordinates,
    'highlight_last_move': highlightLastMove,
    'highlight_possible_moves': highlightPossibleMoves,
    'piece_set': pieceSet,
    'piece_size': pieceSize,
    'sound_enabled': soundEnabled,
    'sound_set': soundSet,
    'vibration_enabled': vibrationEnabled,
    'vibration_intensity': vibrationIntensity,
  };

  UserSettingsModel copyWith({
    String? language,
    String? boardTheme,
    bool? showCoordinates,
    bool? highlightLastMove,
    bool? highlightPossibleMoves,
    String? pieceSet,
    double? pieceSize,
    bool? soundEnabled,
    String? soundSet,
    bool? vibrationEnabled,
    String? vibrationIntensity,
  }) {
    return UserSettingsModel(
      userId: userId,
      language: language ?? this.language,
      boardTheme: boardTheme ?? this.boardTheme,
      showCoordinates: showCoordinates ?? this.showCoordinates,
      highlightLastMove: highlightLastMove ?? this.highlightLastMove,
      highlightPossibleMoves: highlightPossibleMoves ?? this.highlightPossibleMoves,
      pieceSet: pieceSet ?? this.pieceSet,
      pieceSize: pieceSize ?? this.pieceSize,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      soundSet: soundSet ?? this.soundSet,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      vibrationIntensity: vibrationIntensity ?? this.vibrationIntensity,
    );
  }
}