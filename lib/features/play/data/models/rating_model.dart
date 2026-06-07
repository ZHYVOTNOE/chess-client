class RatingModel {
  final String userId;
  final String variant;
  final String timeControl;
  final double rating;
  final DateTime? lastPlayedAt;

  RatingModel({
    required this.userId,
    required this.variant,
    required this.timeControl,
    required this.rating,
    this.lastPlayedAt,
  });

  factory RatingModel.fromJson(Map<String, dynamic> json) {
    return RatingModel(
      userId: json['user_id'] as String,
      variant: json['variant'] as String,
      timeControl: json['time_control'] as String,
      rating: (json['rating'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'variant': variant,
      'time_control': timeControl,
      'rating': rating,
    };
  }

  RatingModel copyWith({
    String? userId,
    String? variant,
    String? timeControl,
    double? rating,
    DateTime? lastPlayedAt,
  }) {
    return RatingModel(
      userId: userId ?? this.userId,
      variant: variant ?? this.variant,
      timeControl: timeControl ?? this.timeControl,
      rating: rating ?? this.rating,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
    );
  }

  /// Returns the rating key for storage (e.g., "standard_blitz")
  String get key => '${variant}_$timeControl';

  /// Returns formatted rating string (e.g., "1500 ± 50")
}
