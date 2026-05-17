import '../../domain/entities/profile_user.dart';
import '../../domain/entities/profile_user_impl.dart';

class ProfileModel implements UserProfile {
  @override final String id;
  @override final String userId;
  @override final String nickname;
  @override final String? avatarUrl;
  @override final DateTime joinedAt;

  ProfileModel({
    required this.id,
    required this.userId,
    required this.nickname,
    this.avatarUrl,
    required this.joinedAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    // 🔥 Безопасное преобразование id: int → String
    final rawId = json['id'];
    final id = rawId is int ? rawId.toString() : rawId as String;

    // 🔥 То же самое для user_id, если нужно
    final rawUserId = json['user_id'];
    final userId = rawUserId is int ? rawUserId.toString() : rawUserId as String;

    return ProfileModel(
      id: id,
      userId: userId,
      nickname: json['nickname'] as String,
      avatarUrl: json['avatar_url'] as String?,
      joinedAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'nickname': nickname,
    'avatar_url': avatarUrl,
    'created_at': joinedAt.toIso8601String(),
  };

  @override
  UserProfile toEntity() => UserProfileImpl(
    id: id,
    userId: userId,
    nickname: nickname,
    avatarUrl: avatarUrl,
    joinedAt: joinedAt,
  );

  @override
  // 🔥 ВАЖНО: возвращаем ProfileModel, а не UserProfile
  ProfileModel copyWith({
    String? id,
    String? userId,
    String? nickname,
    String? avatarUrl,
    DateTime? joinedAt,
  }) => ProfileModel(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    nickname: nickname ?? this.nickname,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    joinedAt: joinedAt ?? this.joinedAt,
  );
}