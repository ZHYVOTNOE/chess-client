class Rating {
  final String variant;
  final String timeControl;
  final double rating;
  final double rd; // Rating deviation
  final double volatility;
  final DateTime? lastPlayedAt;

  Rating({
    required this.variant,
    required this.timeControl,
    required this.rating,
    required this.rd,
    required this.volatility,
    this.lastPlayedAt,
  });

  /// Returns the rating key for storage (e.g., "standard_blitz")
  String get key => '${variant}_$timeControl';

  /// Returns formatted rating string (e.g., "1500 ± 50")
  String get formatted => '${rating.toInt()} ± ${rd.toInt()}';

  Rating copyWith({
    String? variant,
    String? timeControl,
    double? rating,
    double? rd,
    double? volatility,
    DateTime? lastPlayedAt,
  }) {
    return Rating(
      variant: variant ?? this.variant,
      timeControl: timeControl ?? this.timeControl,
      rating: rating ?? this.rating,
      rd: rd ?? this.rd,
      volatility: volatility ?? this.volatility,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
    );
  }
}
