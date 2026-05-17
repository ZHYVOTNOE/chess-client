import 'profile_user.dart';

class UserProfileImpl implements UserProfile {
  @override final String id;
  @override final String userId;
  @override final String nickname;
  @override final String? avatarUrl;
  @override final DateTime joinedAt;

  UserProfileImpl({
    required this.id,
    required this.userId,
    required this.nickname,
    this.avatarUrl,
    required this.joinedAt,
  });

  @override
  UserProfile copyWith({
    String? id,
    String? userId,
    String? nickname,
    String? avatarUrl,
    DateTime? joinedAt,
  }) => UserProfileImpl(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    nickname: nickname ?? this.nickname,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    joinedAt: joinedAt ?? this.joinedAt,
  );
}