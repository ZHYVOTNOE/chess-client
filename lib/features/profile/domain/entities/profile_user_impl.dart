import 'profile_user.dart';

class UserProfileImpl implements UserProfile {
  @override final String id;
  @override final String nickname;
  @override final String? avatarUrl;
  @override final DateTime joinedAt;
  @override final String? fullName;
  @override final String? bio;
  @override final String? countryCode;
  @override final String? title;
  @override final DateTime? lastSeenAt;
  @override final int? displayId;
  @override final Map<String, Rating>? ratings;

  UserProfileImpl({
    required this.id,
    required this.nickname,
    this.avatarUrl,
    required this.joinedAt,
    this.fullName,
    this.bio,
    this.countryCode,
    this.title,
    this.lastSeenAt,
    this.displayId,
    this.ratings,
  });

  @override
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
  }) => UserProfileImpl(
    id: id ?? this.id,
    nickname: nickname ?? this.nickname,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    joinedAt: joinedAt ?? this.joinedAt,
    fullName: fullName ?? this.fullName,
    bio: bio ?? this.bio,
    countryCode: countryCode ?? this.countryCode,
    title: title ?? this.title,
    lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    displayId: displayId ?? this.displayId,
    ratings: ratings ?? this.ratings,
  );
}

class RatingImpl implements Rating {
  @override final String variant;
  @override final String timeControl;
  @override final double rating;
  @override final int gamesPlayed;
  @override final int wins;
  @override final int losses;
  @override final int draws;
  @override final DateTime? lastPlayedAt;

  RatingImpl({
    required this.variant,
    required this.timeControl,
    required this.rating,
    this.gamesPlayed = 0,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.lastPlayedAt,
  });
}
