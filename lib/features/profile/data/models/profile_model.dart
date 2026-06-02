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
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;

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
  );

  Map<String, dynamic> toJson() => {
    'nickname': nickname,
    'avatar_url': avatarUrl,
    'full_name': fullName,
    'bio': bio,
    'country_code': countryCode,
  };
}
