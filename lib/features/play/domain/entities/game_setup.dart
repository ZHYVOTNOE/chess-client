class GameSetup {
  final String userId;
  final String variant;
  final String timeControl;
  final String timeControlCategory;
  final String ratingRange;

  const GameSetup({
    required this.userId,
    required this.variant,
    required this.timeControl,
    required this.timeControlCategory,
    required this.ratingRange,
  });

  GameSetup copyWith({
    String? userId,
    String? variant,
    String? timeControl,
    String? timeControlCategory,
    String? ratingRange,
  }) {
    return GameSetup(
      userId: userId ?? this.userId,
      variant: variant ?? this.variant,
      timeControl: timeControl ?? this.timeControl,
      timeControlCategory: timeControlCategory ?? this.timeControlCategory,
      ratingRange: ratingRange ?? this.ratingRange,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'variant': variant,
      'time_control': timeControl,
      'time_control_category': timeControlCategory,
      'rating_range': ratingRange,
    };
  }

  factory GameSetup.fromMap(Map<String, dynamic> map) {
    return GameSetup(
      userId: map['user_id'] as String,
      variant: map['variant'] as String,
      timeControl: map['time_control'] as String,
      timeControlCategory: map['time_control_category'] as String,
      ratingRange: map['rating_range'] as String,
    );
  }
}
