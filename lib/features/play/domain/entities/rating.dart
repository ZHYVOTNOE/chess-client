class Rating {
  final String variant;
  final String timeControl;
  final double rating;
  final DateTime? lastPlayedAt;

  Rating({
    required this.variant,
    required this.timeControl,
    required this.rating,
    this.lastPlayedAt,
  });

  /// Returns the rating key for storage (e.g., "standard_blitz")
  String get key => '${variant}_$timeControl';

  /// Returns formatted rating string (e.g., "1500 ± 50")
  Rating copyWith({
    String? variant,
    String? timeControl,
    double? rating,
    DateTime? lastPlayedAt,
  }) {
    return Rating(
      variant: variant ?? this.variant,
      timeControl: timeControl ?? this.timeControl,
      rating: rating ?? this.rating,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
    );
  }
}
