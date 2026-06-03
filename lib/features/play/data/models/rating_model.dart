class RatingModel {
  final String userId;
  final String variant;
  final String timeControl;
  final double rating;
  final double rd; // Rating deviation
  final double volatility;
  final int gamesPlayed;
  final int wins;
  final int losses;
  final int draws;
  final DateTime? lastPlayedAt;

  RatingModel({
    required this.userId,
    required this.variant,
    required this.timeControl,
    required this.rating,
    required this.rd,
    required this.volatility,
    this.gamesPlayed = 0,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.lastPlayedAt,
  });

  factory RatingModel.fromJson(Map<String, dynamic> json) {
    return RatingModel(
      userId: json['user_id'] as String,
      variant: json['variant'] as String,
      timeControl: json['time_control'] as String,
      rating: (json['rating'] as num).toDouble(),
      rd: (json['rd'] as num).toDouble(),
      volatility: (json['volatility'] as num).toDouble(),
      gamesPlayed: json['games_played'] as int? ?? 0,
      wins: json['wins'] as int? ?? 0,
      losses: json['losses'] as int? ?? 0,
      draws: json['draws'] as int? ?? 0,
      lastPlayedAt: json['last_played_at'] != null
          ? DateTime.parse(json['last_played_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'variant': variant,
      'time_control': timeControl,
      'rating': rating,
      'rd': rd,
      'volatility': volatility,
      'games_played': gamesPlayed,
      'wins': wins,
      'losses': losses,
      'draws': draws,
      'last_played_at': lastPlayedAt?.toIso8601String(),
    };
  }

  RatingModel copyWith({
    String? userId,
    String? variant,
    String? timeControl,
    double? rating,
    double? rd,
    double? volatility,
    int? gamesPlayed,
    int? wins,
    int? losses,
    int? draws,
    DateTime? lastPlayedAt,
  }) {
    return RatingModel(
      userId: userId ?? this.userId,
      variant: variant ?? this.variant,
      timeControl: timeControl ?? this.timeControl,
      rating: rating ?? this.rating,
      rd: rd ?? this.rd,
      volatility: volatility ?? this.volatility,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      draws: draws ?? this.draws,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
    );
  }

  /// Returns the rating key for storage (e.g., "standard_blitz")
  String get key => '${variant}_$timeControl';

  /// Returns formatted rating string (e.g., "1500 ± 50")
  String get formatted => '${rating.toInt()} ± ${rd.toInt()}';
}
