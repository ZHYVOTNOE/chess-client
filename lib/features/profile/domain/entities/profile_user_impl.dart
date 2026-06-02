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
  );
}
