abstract class UserProfile {
  String get id;
  String get userId;
  String get nickname;
  String? get avatarUrl;
  DateTime get joinedAt;

  UserProfile copyWith({
    String? id,
    String? userId,
    String? nickname,
    String? avatarUrl,
    DateTime? joinedAt,
  });
}