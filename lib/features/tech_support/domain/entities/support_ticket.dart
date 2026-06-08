class SupportTicket {
  final String id;
  final String userId;
  final String? assignedAdminId;
  final String status; // 'open' | 'closed'
  final DateTime createdAt;
  final DateTime updatedAt;

  // Обогащённые данные (из join с profiles)
  final String? userNickname;
  final String? userAvatarUrl;
  final String? lastMessageText;

  const SupportTicket({
    required this.id,
    required this.userId,
    this.assignedAdminId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.userNickname,
    this.userAvatarUrl,
    this.lastMessageText,
  });

  bool get isOpen => status == 'open';

  SupportTicket copyWith({
    String? status,
    DateTime? updatedAt,
    String? lastMessageText,
  }) {
    return SupportTicket(
      id: id,
      userId: userId,
      assignedAdminId: assignedAdminId,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userNickname: userNickname,
      userAvatarUrl: userAvatarUrl,
      lastMessageText: lastMessageText ?? this.lastMessageText,
    );
  }
}
