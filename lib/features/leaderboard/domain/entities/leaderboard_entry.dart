class LeaderboardEntry {
  final int rank;
  final String userId;
  final String nickname;
  final String? avatarUrl;
  final String? title;
  final String? countryCode;
  final double rating;
  final String variantKey;
  final String? timeControlType;

  LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.nickname,
    this.avatarUrl,
    this.title,
    this.countryCode,
    required this.rating,
    required this.variantKey,
    this.timeControlType,
  });

  LeaderboardEntry copyWith({
    int? rank,
    String? userId,
    String? nickname,
    String? avatarUrl,
    String? title,
    String? countryCode,
    double? rating,
    String? variantKey,
    String? timeControlType,
  }) {
    return LeaderboardEntry(
      rank: rank ?? this.rank,
      userId: userId ?? this.userId,
      nickname: nickname ?? this.nickname,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      title: title ?? this.title,
      countryCode: countryCode ?? this.countryCode,
      rating: rating ?? this.rating,
      variantKey: variantKey ?? this.variantKey,
      timeControlType: timeControlType ?? this.timeControlType,
    );
  }
}
