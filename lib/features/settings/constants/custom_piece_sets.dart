class PieceSetEntry {
  final String id;           // 'merida', 'staunton', etc.
  final String label;        // 'Merida', 'Staunton' — для UI
  final String license;      // 'CC0', 'CC BY-SA 4.0', etc.
  final String sourceUrl;    // ссылка на оригинал (для атрибуции)

  const PieceSetEntry({
    required this.id,
    required this.label,
    required this.license,
    this.sourceUrl = 'https://github.com/lichess-org/lila/tree/master/public/piece',
  });
}

/// Все доступные наборы фигур (на основе Lichess + твои)
class CustomPieceSets {
  // 🔥 CC0 1.0 (Public Domain) — можно использовать без ограничений
  static const merida = PieceSetEntry(
    id: 'merida',
    label: 'Merida',
    license: 'CC0 1.0',
  );

  static const staunton = PieceSetEntry(
    id: 'staunton',
    label: 'Staunton',
    license: 'CC0 1.0',
  );

  static const alpha = PieceSetEntry(
    id: 'alpha',
    label: 'Alpha',
    license: 'CC0 1.0',
  );

  static const pixel = PieceSetEntry(
    id: 'pixel',
    label: 'Pixel',
    license: 'CC0 1.0',
  );

  // 🔥 CC BY-SA 4.0 — можно использовать, но нужно указать автора
  static const cardinal = PieceSetEntry(
    id: 'cardinal',
    label: 'Cardinal',
    license: 'CC BY-SA 4.0',
    sourceUrl: 'https://github.com/lichess-org/lila/tree/master/public/piece/cardinal',
  );

  static const leipzig = PieceSetEntry(
    id: 'leipzig',
    label: 'Leipzig',
    license: 'CC BY-SA 4.0',
    sourceUrl: 'https://github.com/lichess-org/lila/tree/master/public/piece/leipzig',
  );

  // 🔥 Полный список (можно расширять)
  static const List<PieceSetEntry> all = [
    // CC0 — безопасные для старта
    merida,
    staunton,
    alpha,
    pixel,

    // CC BY-SA — добавляй, когда будешь готов к атрибуции
    // cardinal,
    // leipzig,
    // chess7,
    // ... и другие
  ];

  /// Получить набор по ID
  static PieceSetEntry? getById(String id) {
    return all.firstWhere((entry) => entry.id == id, orElse: () => merida);
  }

  /// Проверить, требует ли набор атрибуции
  static bool requiresAttribution(String id) {
    final entry = getById(id);
    return entry?.license.contains('BY') ?? false;
  }
}