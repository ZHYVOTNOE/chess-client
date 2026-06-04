import '../../domain/entities/leaderboard_entry.dart';

class LeaderboardModel {
  final int rank;
  final String userId;
  final String nickname;
  final String? fullName;
  final String? avatarUrl;
  final String? title;
  final String? countryCode;
  final double rating;
  final String variantKey;
  final String? timeControlType;

  LeaderboardModel({
    required this.rank,
    required this.userId,
    required this.nickname,
    this.fullName,
    this.avatarUrl,
    this.title,
    this.countryCode,
    required this.rating,
    required this.variantKey,
    this.timeControlType,
  });

  factory LeaderboardModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardModel(
      rank: json['rank'] as int? ?? 0,
      userId: json['user_id'] as String,
      nickname: json['nickname'] as String,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      title: json['title'] as String?,
      countryCode: json['country_code'] as String?,
      rating: (json['rating'] as num).toDouble(),
      variantKey: json['variant_key'] as String,
      timeControlType: json['time_control_type'] as String?,
    );
  }

  LeaderboardEntry toEntity() {
    return LeaderboardEntry(
      rank: rank,
      userId: userId,
      nickname: nickname,
      fullName: fullName,
      avatarUrl: avatarUrl,
      title: title,
      countryCode: countryCode,
      rating: rating,
      variantKey: variantKey,
      timeControlType: timeControlType,
    );
  }
}
