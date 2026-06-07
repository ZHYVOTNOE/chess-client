abstract class UserProfile {
  String get id; // Это твой UUID из Auth
  String get nickname;
  String? get avatarUrl;
  DateTime get joinedAt;
  String? get fullName;
  String? get bio;
  String? get countryCode;
  String? get title;
  DateTime? get lastSeenAt;
  int? get displayId; // Это твой 10-значный игровой ID
  Map<String, Rating>? get ratings; // Glicko-2 ratings: key = "variant_timeControl" (e.g., "standard_blitz")

  UserProfile copyWith({
    String? id,
    String? nickname,
    String? avatarUrl,
    DateTime? joinedAt,
    String? fullName,
    String? bio,
    String? countryCode,
    String? title,
    DateTime? lastSeenAt,
    int? displayId,
    Map<String, Rating>? ratings,
  });
}

abstract class Rating {
  String get variant;
  String get timeControl;
  double get rating;
  int get gamesPlayed;
  int get wins;
  int get losses;
  int get draws;
  DateTime? get lastPlayedAt;
}