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
  final String? friendAvatarUrl;
  final FriendStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int? rating;
  final bool isOnline;

  Friend({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.friendNickname,
    this.friendFullName,
    this.friendBio,
    this.friendAvatarUrl,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.rating,
    this.isOnline = false,
  });

  /// Check if this is a pending request sent by the current user
  bool get isSentRequest => status == FriendStatus.pending;

  /// Check if this is a pending request received by the current user
  bool get isReceivedRequest => status == FriendStatus.pending;

  /// Check if this is an accepted friend
  bool get isFriend => status == FriendStatus.accepted;

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
    bool? isOnline,
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
      isOnline: isOnline ?? this.isOnline,
    );
  }
}
