class PieceSetEntry {
  final String id;
  final String label;
  final String license;
  final String sourceUrl;

  const PieceSetEntry({
    required this.id,
    required this.label,
    required this.license,
    this.sourceUrl = 'https://github.com/lichess-org/lila/tree/master/public/piece',
  });
}

class CustomPieceSets {
  static const merida = PieceSetEntry(
    id: 'merida',
    label: 'Merida',
    license: 'CC0 1.0',
  );

  static const staunty = PieceSetEntry(
    id: 'staunty',
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

  static const letter = PieceSetEntry(
    id: 'letter',
    label: 'Буквы',
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