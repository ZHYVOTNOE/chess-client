import '../../domain/entities/profile_user.dart';
import '../../domain/entities/profile_user_impl.dart';

class ProfileModel implements UserProfile {
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

  ProfileModel({
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

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;

    // Parse ratings from JSON
    Map<String, Rating>? ratings;
    if (json['ratings'] != null) {
      ratings = {};
      final ratingsData = json['ratings'] as Map<String, dynamic>;
      ratingsData.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          ratings![key] = RatingImpl(
            variant: value['variant'] as String? ?? 'standard',
            timeControl: value['time_control'] as String? ?? 'blitz',
            rating: (value['rating'] as num?)?.toDouble() ?? 1200.0,
            rd: (value['rd'] as num?)?.toDouble() ?? 350.0,
            volatility: (value['volatility'] as num?)?.toDouble() ?? 0.06,
            gamesPlayed: value['games_played'] as int? ?? 0,
            wins: value['wins'] as int? ?? 0,
            losses: value['losses'] as int? ?? 0,
            draws: value['draws'] as int? ?? 0,
            lastPlayedAt: value['last_played_at'] != null
                ? DateTime.parse(value['last_played_at'] as String)
                : null,
          );
        }
      });
    }

    return ProfileModel(
      id: id,
      nickname: json['nickname'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      joinedAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      fullName: json['full_name'] as String?,
      bio: json['bio'] as String?,
      countryCode: json['country_code'] as String?,
      title: json['title'] as String?,
      lastSeenAt: json['last_seen_at'] != null
          ? DateTime.parse(json['last_seen_at'] as String)
          : null,
      displayId: json['display_id'] as int?,
      ratings: ratings,
    );
  }

  @override
  UserProfile toEntity() => UserProfileImpl(
    id: id,
    nickname: nickname,
    avatarUrl: avatarUrl,
    joinedAt: joinedAt,
    fullName: fullName,
    bio: bio,
    countryCode: countryCode,
    title: title,
    lastSeenAt: lastSeenAt,
    displayId: displayId,
    ratings: ratings,
  );

  @override
  ProfileModel copyWith({
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
  }) => ProfileModel(
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

  Map<String, dynamic> toJson() => {
    'nickname': nickname,
    'avatar_url': avatarUrl,
    'full_name': fullName,
    'bio': bio,
    'country_code': countryCode,
  };
}
