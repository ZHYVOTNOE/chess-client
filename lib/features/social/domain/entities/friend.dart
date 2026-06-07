enum FriendStatus {
  pending,
  accepted,
  declined,
}

class Friend {
  final String id;
  final String userId;
  final String friendId;
  final String friendNickname;
  final String? friendFullName;
  final String? friendBio;
  final DateTime? lastSeenAt;
  final String? friendAvatarUrl;
  final FriendStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int? rating;
  final String? title;
  final String? countryCode;
  final String role; // 'user' | 'admin'

  Friend({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.friendNickname,
    this.friendFullName,
    this.friendBio,
    this.lastSeenAt,
    this.friendAvatarUrl,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.rating,
    this.title,
    this.countryCode,
    this.role = 'user',
  });

  bool get isSentRequest => status == FriendStatus.pending;
  bool get isReceivedRequest => status == FriendStatus.pending;
  bool get isFriend => status == FriendStatus.accepted;
  bool get isAdmin => role == 'admin';

  Friend copyWith({
    String? id,
    String? userId,
    String? friendId,
    String? friendNickname,
    String? friendFullName,
    String? friendBio,
    String? friendAvatarUrl,
    FriendStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? rating,
    String? title,
    String? countryCode,
    String? role,
  }) {
    return Friend(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      friendId: friendId ?? this.friendId,
      friendNickname: friendNickname ?? this.friendNickname,
      friendFullName: friendFullName ?? this.friendFullName,
      friendBio: friendBio ?? this.friendBio,
      friendAvatarUrl: friendAvatarUrl ?? this.friendAvatarUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rating: rating ?? this.rating,
      title: title ?? this.title,
      countryCode: countryCode ?? this.countryCode,
      role: role ?? this.role,
    );
  }
}