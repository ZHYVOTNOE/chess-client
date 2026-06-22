class PieceSetEntry {
  final String id;
  final String labelKey; // 🔥 Ключ локализации
  final String license;
  final String sourceUrl;

  const PieceSetEntry({
    required this.id,
    required this.labelKey,
    required this.license,
    this.sourceUrl = 'https://github.com/lichess-org/lila/tree/master/public/piece',
  });
}

class CustomPieceSets {
  static const merida = PieceSetEntry(
    id: 'merida',
    labelKey: 'piece_set_merida',
    license: 'CC0 1.0',
  );

  static const staunty = PieceSetEntry(
    id: 'staunty',
    labelKey: 'piece_set_staunty',
    license: 'CC0 1.0',
  );

  static const alpha = PieceSetEntry(
    id: 'alpha',
    labelKey: 'piece_set_alpha',
    license: 'CC0 1.0',
  );

  static const pixel = PieceSetEntry(
    id: 'pixel',
    labelKey: 'piece_set_pixel',
    license: 'CC0 1.0',
  );

  static const letter = PieceSetEntry(
    id: 'letter',
    labelKey: 'piece_set_letter',
    license: 'CC0 1.0',
  );

  static const List<PieceSetEntry> all = [
    merida,
    staunty,
    alpha,
    pixel,
    letter,
  ];

  static PieceSetEntry? getById(String id) {
    return all.firstWhere(
          (entry) => entry.id == id,
      orElse: () => merida,
    );
  }

  static bool requiresAttribution(String id) {
    final entry = getById(id);
    return entry?.license.contains('BY') ?? false;
  }
}